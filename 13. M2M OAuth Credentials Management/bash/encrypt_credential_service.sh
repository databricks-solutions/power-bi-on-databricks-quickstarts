#!/usr/bin/env bash

#
# Equivalent of encrypt_credential_service.ps1 implemented in Bash.
# Provides functions to encrypt Power BI datasource credentials for gateways
# using RSA-OAEP with SHA-256 and a hybrid scheme for higher key sizes.
#
# Ported closely from the original PowerShell implementation; logic and
# comments mirror the source as much as possible.
#

#set -euo pipefail

# --- Dependencies check ---
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Error: required command '$1' not found in PATH" >&2; exit 1; }; }
need_cmd openssl
need_cmd base64
need_cmd xxd

# Decode base64 content to a file (macOS and Linux compatible), binary-safe
decode_b64_to_file() {
  local content="$1" outfile="$2"
  if printf '%s' "${content}" | base64 -D >"${outfile}" 2>/dev/null; then
    :
  else
    printf '%s' "${content}" | base64 -d >"${outfile}" 2>/dev/null
  fi
}

# Build a PEM public key from Base64 modulus and exponent
# Arguments:
#   $1: exponent (Base64)
#   $2: modulus (Base64)
#   $3: output PEM file path
build_rsa_pub_from_modexp() {
  local exponent_b64="$1"
  local modulus_b64="$2"
  local out_pem="$3"

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' EXIT

  local mod_hex exp_hex
  decode_b64_to_file "${modulus_b64}" "${tmpdir}/modulus.bin"
  decode_b64_to_file "${exponent_b64}" "${tmpdir}/exponent.bin"
  mod_hex="$(xxd -p -c 1000 "${tmpdir}/modulus.bin" | tr -d '\n' | tr 'A-F' 'a-f')"
  exp_hex="$(xxd -p -c 1000 "${tmpdir}/exponent.bin" | tr -d '\n' | tr 'A-F' 'a-f')"

  # Generate PKCS#1 RSAPublicKey DER via openssl asn1parse -genconf
  cat >"${tmpdir}/rsa_pub.cnf" <<EOF
asn1=SEQUENCE:pubkey

[pubkey]
modulus=INTEGER:0x${mod_hex}
publicExponent=INTEGER:0x${exp_hex}
EOF

  openssl asn1parse -genconf "${tmpdir}/rsa_pub.cnf" -out "${tmpdir}/rsa_pub.der" >/dev/null 2>&1
  # Convert PKCS#1 DER to SPKI PEM
  openssl rsa -RSAPublicKey_in -inform DER -in "${tmpdir}/rsa_pub.der" -pubout -out "${out_pem}" >/dev/null 2>&1
}

# RSA-OAEP-SHA256 encrypt arbitrary data with given PEM public key
#   $1: input file
#   $2: public key PEM
#   $3: output file (binary)
rsa_oaep_sha256_encrypt_file() {
  local in_file="$1" pub_pem="$2" out_file="$3"
  openssl pkeyutl -encrypt -pubin -inkey "${pub_pem}" \
    -pkeyopt rsa_padding_mode:oaep \
    -pkeyopt rsa_oaep_md:sha256 \
    -pkeyopt rsa_mgf1_md:sha256 \
    -in "${in_file}" -out "${out_file}"
}

# AES-256-CBC (PKCS7) encrypt
#   $1: key (hex, 64 chars)
#   $2: iv (hex, 32 chars)
#   $3: input file
#   $4: output file (binary)
aes256cbc_pkcs7_encrypt_file() {
  local key_hex="$1" iv_hex="$2" in_file="$3" out_file="$4"
  openssl enc -aes-256-cbc -K "${key_hex}" -iv "${iv_hex}" -nosalt -in "${in_file}" -out "${out_file}"
}

# HMAC-SHA256 over input
#   $1: key (hex)
#   $2: input file
#   $3: output file (raw binary mac)
hmac_sha256_file() {
  local key_hex="$1" in_file="$2" out_file="$3"
  # openssl dgst writes hex by default; use -binary for raw
  openssl dgst -sha256 -mac HMAC -macopt "hexkey:${key_hex}" -binary "${in_file}" >"${out_file}"
}

# EncodeCredentials equivalent
#   Inputs:
#     GATEWAY_EXPONENT_B64  (env or arg)
#     GATEWAY_MODULUS_B64   (env or arg)
#     CREDENTIALS_JSON      (env or arg)
#   Output:
#     Writes encrypted credentials string to stdout
encode_credentials() {
  local exponent_b64="$1"
  local modulus_b64="$2"
  local credentials_json="$3"

  if [[ -z "${credentials_json}" ]]; then
    echo "credentials data required" >&2
    exit 1
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' EXIT

  # Prepare plaintext bytes
  printf '%s' "${credentials_json}" >"${tmpdir}/plain.bin"

  # Decode modulus to check size in bytes
  local modulus_raw_len
  decode_b64_to_file "${modulus_b64}" "${tmpdir}/modulus.bin"
  modulus_raw_len="$(wc -c <"${tmpdir}/modulus.bin" | tr -d ' ')"

  # Build public key
  build_rsa_pub_from_modexp "${exponent_b64}" "${modulus_b64}" "${tmpdir}/pub.pem"

  if [[ "${modulus_raw_len}" -eq 128 ]]; then
    # Asymmetric1024KeyEncryptionHelper path
    # SEGMENT_LENGTH = 60, ENCRYPTED_LENGTH = 128
    local seg_len=60 enc_len=128
    local total_len
    total_len="$(wc -c <"${tmpdir}/plain.bin" | tr -d ' ')"
    local has_incomplete=$(( total_len % seg_len ))
    local segments=$(( (total_len + seg_len - 1) / seg_len ))

    : >"${tmpdir}/encrypted_all.bin"
    local i=0
    while [[ $i -lt ${segments} ]]; do
      local offset=$(( i * seg_len ))
      local length=$seg_len
      if [[ $(( i )) -eq $(( segments - 1 )) && ${has_incomplete} -ne 0 ]]; then
        length=${has_incomplete}
      fi
      dd if="${tmpdir}/plain.bin" of="${tmpdir}/segment.bin" bs=1 skip=${offset} count=${length} status=none
      rsa_oaep_sha256_encrypt_file "${tmpdir}/segment.bin" "${tmpdir}/pub.pem" "${tmpdir}/segment.enc"
      cat "${tmpdir}/segment.enc" >>"${tmpdir}/encrypted_all.bin"
      i=$(( i + 1 ))
    done
    base64 <"${tmpdir}/encrypted_all.bin" | tr -d '\n'
    return 0
  else
    # AsymmetricHigherKeyEncryptionHelper path
    # Generate random keys: AES-256 (32 bytes) and HMAC (64 bytes)
    openssl rand -out "${tmpdir}/key_enc.bin" 32
    openssl rand -out "${tmpdir}/key_mac.bin" 64
    local key_enc_hex key_mac_hex
    key_enc_hex="$(xxd -p -c 1000 "${tmpdir}/key_enc.bin" | tr -d '\n')"
    key_mac_hex="$(xxd -p -c 1000 "${tmpdir}/key_mac.bin" | tr -d '\n')"

    # Encrypt plaintext with AES-256-CBC + PKCS7
    openssl rand -out "${tmpdir}/iv.bin" 16
    local iv_hex
    iv_hex="$(xxd -p -c 1000 "${tmpdir}/iv.bin" | tr -d '\n')"

    aes256cbc_pkcs7_encrypt_file "${key_enc_hex}" "${iv_hex}" "${tmpdir}/plain.bin" "${tmpdir}/cipher.bin"

    # Build AlgorithmChoices (two zero bytes), then IV and CipherText for tag
    printf '\x00\x00' >"${tmpdir}/alg.bin"
    cat "${tmpdir}/alg.bin" "${tmpdir}/iv.bin" "${tmpdir}/cipher.bin" >"${tmpdir}/tagdata.bin"

    # HMAC-SHA256 over tagdata
    hmac_sha256_file "${key_mac_hex}" "${tmpdir}/tagdata.bin" "${tmpdir}/mac.bin"

    # Build final output bytes: AlgorithmChoices + MAC + IV + CipherText
    cat "${tmpdir}/alg.bin" "${tmpdir}/mac.bin" "${tmpdir}/iv.bin" "${tmpdir}/cipher.bin" >"${tmpdir}/output.bin"

    # RSA encrypt keys: [0x00,0x01] + keyEnc + keyMac
    printf '\x00\x01' >"${tmpdir}/keys.bin"
    cat "${tmpdir}/key_enc.bin" "${tmpdir}/key_mac.bin" >>"${tmpdir}/keys.bin"
    rsa_oaep_sha256_encrypt_file "${tmpdir}/keys.bin" "${tmpdir}/pub.pem" "${tmpdir}/keys.enc"

    # Return base64(RSA(keys)) + base64(ciphertext)
    local rsa_b64 cipher_b64
    rsa_b64="$(base64 <"${tmpdir}/keys.enc" | tr -d '\n')"
    cipher_b64="$(base64 <"${tmpdir}/output.bin" | tr -d '\n')"
    printf '%s%s' "${rsa_b64}" "${cipher_b64}"
    return 0
  fi
}

# If invoked directly, allow simple CLI usage:
#   ./encrypt_credential_service.sh <exponent_b64> <modulus_b64> <credentials_json>
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <exponent_b64> <modulus_b64> <credentials_json>" >&2
    exit 2
  fi
  encode_credentials "$1" "$2" "$3"
fi
