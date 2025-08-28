#!/usr/bin/env bash

# .SYNOPSIS
# This script rotates the Databricks Service Principal credentials for Power BI and Databricks integration.
# .DESCRIPTION
# This script rotates the Databricks Service Principal credentials for Power BI and Databricks integration, updating the SQL Warehouse permissions and dataset credentials.
# .PARAMETER ServicePrincipal
# The name of the Databricks Service Principal to create or update.
# .PARAMETER WarehouseId
# The SQL Warehouse ID to be used by the Databricks Service Principal.
# .PARAMETER Workspace
# The name of the Power BI workspace.
# .PARAMETER Dataset
# The name of the Power BI dataset.
# .PARAMETER GatewayType
# The type of the gateway used by the Power BI semantic model. Valid values are "NoGateway", "VNET", and "Onpremises". Default is "Onpremises".
# .PARAMETER Lifetime
# The secret lifetime in seconds. Default is 604800 seconds (7 days).
# .PARAMETER RefreshDataset
# If specified, the dataset will be refreshed after updating the credentials.
# .PARAMETER SecretScope
# The name of the Databricks secret scope where Entra ID Service Principal details are stored.
# .PARAMETER ClientIdSecret
# The name of the Databricks secret scope where Entra ID Service Principal Client ID is stored.
# .PARAMETER SecretSecret
# The name of the Databricks secret scope where Entra ID Service Principal Secret is stored.
# .PARAMETER TenantIdSecret
# The name of the Databricks secret scope where Entra ID Service Principal Tenant ID is stored.
# .PARAMETER Profile
# The Databricks CLI profile to use, default is "DEFAULT".
# .OUTPUTS
# None
# .EXAMPLE
# Update-M2M-OAuth-Credentials.sh --ServicePrincipal "MySPN" --WarehouseId "44ff20e73e461e56" --Workspace "SPN-rotation-test" --Dataset "tpch" --Lifetime 60 --RefreshDataset -SecretScope "powerbi_credentials" --ClientIdSecret "powerbi_client_id" --SecretSecret "powerbi_client_secret" --TenantIdSecret "powerbi_tenant_id" --RefreshDataset
# .LINK
# None

set -euo pipefail

# Defaults (mirroring the PowerShell script)
SERVICE_PRINCIPAL_NAME="MyServicePrincipal"
WAREHOUSE_ID="a5ad4687dadae274"
WORKSPACE_NAME="SPN-rotation-test"
DATASET_NAME="tpch-no-gateway"
GATEWAY_TYPE="NoGateway"
LIFETIME=604800
REFRESH_DATASET=false
SECRET_SCOPE="powerbi_credentials"
CLIENT_ID_SECRET="powerbi_client_id"
SECRET_SECRET="powerbi_client_secret"
TENANT_ID_SECRET="powerbi_tenant_id"
PROFILE="DEFAULT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Helpers ---
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Error: required command '$1' not found" >&2; exit 1; }; }

compare_versions() {
  # returns: -1 if $1<$2, 0 if ==, 1 if $1>$2
  local IFS=.
  local i ver1=($1) ver2=($2)
  # fill empty fields in ver1 with zeros
  for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do ver1[i]=0; done
  for ((i=0; i<${#ver1[@]}; i++)); do
    [[ -z ${ver2[i]:-} ]] && ver2[i]=0
    if ((10#${ver1[i]} < 10#${ver2[i]})); then echo -1; return; fi
    if ((10#${ver1[i]} > 10#${ver2[i]})); then echo 1; return; fi
  done
  echo 0
}

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

# --- Args parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ServicePrincipal|-s) SERVICE_PRINCIPAL_NAME="$2"; shift 2;;
    --WarehouseId|-w) WAREHOUSE_ID="$2"; shift 2;;
    --Workspace) WORKSPACE_NAME="$2"; shift 2;;
    --Dataset) DATASET_NAME="$2"; shift 2;;
    --GatewayType) GATEWAY_TYPE="$2"; shift 2;;
    --Lifetime) LIFETIME="$2"; shift 2;;
    --RefreshDataset) REFRESH_DATASET=true; shift 1;;
    --SecretScope) SECRET_SCOPE="$2"; shift 2;;
    --ClientIdSecret) CLIENT_ID_SECRET="$2"; shift 2;;
    --SecretSecret) SECRET_SECRET="$2"; shift 2;;
    --TenantIdSecret) TENANT_ID_SECRET="$2"; shift 2;;
    --Profile) PROFILE="$2"; shift 2;;
    -h|--help)
      sed -n '1,40p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) log_error "Unknown argument: $1"; exit 2;;
  esac
done

# --- Checks ---
need_cmd databricks
need_cmd jq
need_cmd curl
#need_cmd az

# Databricks CLI version check
required_version="0.264.2"
current_version="$(databricks -v | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')"
if [[ -z "${current_version}" ]]; then
  log_error "Unable to determine Databricks CLI version"
  exit 1
fi
cmp="$(compare_versions "${current_version}" "${required_version}")"
if [[ "${cmp}" -lt 0 ]]; then
  log_error "Databricks CLI version is below ${required_version}. Please update it to continue."
  exit 1
else
  log_info "Databricks CLI version is ${current_version} (>= ${required_version}). Proceeding..."
fi


# ========================== Databricks Service Principal management ========================

log_info "Checking if Service Principal ${SERVICE_PRINCIPAL_NAME} exists..."
spn_json="$(databricks service-principals list --filter "displayName eq ${SERVICE_PRINCIPAL_NAME}" --output json --profile "${PROFILE}" || true)"
spn_id="$(printf '%s' "${spn_json}" | jq -r '.[0].id // empty')"
app_id="$(printf '%s' "${spn_json}" | jq -r '.[0].applicationId // empty')"


if [[ -z "${spn_id}" ]]; then
  log_info "Creating Service Principal ${SERVICE_PRINCIPAL_NAME}..."
  spn_create_json="$(databricks service-principals create --display-name "${SERVICE_PRINCIPAL_NAME}" --output json --profile "${PROFILE}")"
  spn_id="$(printf '%s' "${spn_create_json}" | jq -r '.id')"
  app_id="$(printf '%s' "${spn_create_json}" | jq -r '.applicationId')"
fi
log_info "Service Principal info: id=${spn_id} appId=${app_id}"


log_info "Getting the list of secrets..."
secrets_json="$(databricks service-principal-secrets-proxy list "${spn_id}" --output json --profile "${PROFILE}" || echo '[]')"
secrets_count="$(printf '%s' "${secrets_json}" | jq 'length')"
log_info "Secrets count: ${secrets_count}"
if [[ "${secrets_count}" -eq 5 ]]; then
  log_error "Service Principal ${SERVICE_PRINCIPAL_NAME} has already 5 secrets. Creating more than 5 secrets is not supported. Please delete some of the secrets to continue."
  exit 1
fi


log_info "Creating Secret..."
secret_json="$(databricks service-principal-secrets-proxy create "${spn_id}" --lifetime "${LIFETIME}s" --output json --profile "${PROFILE}")"
secret_value="$(printf '%s' "${secret_json}" | jq -r '.secret')"


# Grant Databricks Service Principal CAN USE permissions on the SQL Warehouse
log_info "Granting Service Principal ${SERVICE_PRINCIPAL_NAME} CAN USE permission on SQL Warehouse "${WAREHOUSE_ID}"..."
perm_json="$(jq -n --arg sp "${app_id}" '{access_control_list:[{service_principal_name:$sp, permission_level:"CAN_USE"}]}')"
databricks warehouses set-permissions "${WAREHOUSE_ID}" --json "${perm_json}" --profile "${PROFILE}" >/dev/null


### ========================= Power BI Integration ======================== ###

# Get the Entra ID Service Principal details from Databricks secrets
log_info "Getting Entra ID Service Principal..."
client_id="$(databricks secrets get-secret "${SECRET_SCOPE}" "${CLIENT_ID_SECRET}" --output json --profile "${PROFILE}" | jq -r .value | base64 --decode)"
secret="$(databricks secrets get-secret "${SECRET_SCOPE}" "${SECRET_SECRET}" --output json --profile "${PROFILE}" | jq -r .value | base64 --decode)"
tenant_id="$(databricks secrets get-secret "${SECRET_SCOPE}" "${TENANT_ID_SECRET}" --output json --profile "${PROFILE}" | jq -r .value | base64 --decode)"
log_info "Entra ID Service Principal info: appId=${client_id} tenantId=${tenant_id}"

# Acquire Power BI access token via Azure CLI
#log_info "Acquiring Power BI access token..."
#access_token="$(az account get-access-token --resource "https://analysis.windows.net/powerbi/api" --query accessToken -o tsv)"
#if [[ -z "${access_token}" ]]; then
#  log_error "Failed to obtain Power BI access token. Ensure 'az login' has been performed."
#  exit 1
#fi


# Get the Power BI access token using the Entra ID Service Principal
log_info "Acquiring Power BI access token..."
token_url="https://login.microsoftonline.com/$tenant_id/oauth2/v2.0/token"
scope="https://analysis.windows.net/powerbi/api/.default"
access_token="$(curl -s -X POST $token_url -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=client_credentials&client_id=$client_id&client_secret=$secret&scope=$scope" | jq -r '.access_token')"
auth_header=("Authorization: Bearer ${access_token}")
content_type=("Content-Type: application/json")


# Get the list of Power BI workspaces
log_info "Getting the list of workspaces..."
groups_json="$(curl -sS -H "${auth_header[@]}" -H "${content_type[@]}" "https://api.powerbi.com/v1.0/myorg/groups")"
# Find the workspace with the specified name  
workspace_id="$(printf '%s' "${groups_json}" | jq -r --arg n "${WORKSPACE_NAME}" '.value[] | select(.name==$n) | .id' | head -n1)"
if [[ -z "${workspace_id}" ]]; then
  log_error "The workspace ${WORKSPACE_NAME} has not been found."
  exit 1
fi


# Get the list of datasets in the Power BI workspace
log_info "Getting the list of datasets..."
datasets_json="$(curl -sS -H "${auth_header[@]}" -H "${content_type[@]}" "https://api.powerbi.com/v1.0/myorg/groups/${workspace_id}/datasets")"
# Find the dataset with the specified name
dataset_id="$(printf '%s' "${datasets_json}" | jq -r --arg n "${DATASET_NAME}" '.value[] | select(.name==$n) | .id' | head -n1)"
if [[ -z "${dataset_id}" ]]; then
  log_error "The dataset ${DATASET_NAME} has not been found."
  exit 1
fi


# Take over the Power BI dataset to be able to update the credentials
if [[ "$GATEWAY_TYPE" == "NoGateway" ]]; then
  log_info "Taking over the dataset..."
  curl -sS -X POST -H "${auth_header[@]}" -H "${content_type[@]}" "https://api.powerbi.com/v1.0/myorg/groups/${workspace_id}/datasets/${dataset_id}/Default.TakeOver" -d '{}' >/dev/null
fi


# Get the list of datasources for the Power BI dataset
log_info "Getting the list of datasources..."
datasources_json="$(curl -sS -H "${auth_header[@]}" -H "${content_type[@]}" "https://api.powerbi.com/v1.0/myorg/groups/${workspace_id}/datasets/${dataset_id}/datasources")"
# Find the datasource with the kind 'Databricks*'
datasource_line="$(printf '%s' "${datasources_json}" | jq -r '.value[] | select(((.ConnectionDetails.kind // .connectionDetails.kind // "") | test("^Databricks"))) | [.datasourceId, .gatewayId] | @tsv' | head -n1)"
if [[ -z "${datasource_line}" ]]; then
  log_error "Databricks datasource has not been found."
  exit 1
fi
datasource_id="${datasource_line%%$'\t'*}"
gateway_id="${datasource_line##*$'\t'}"


username="${app_id}"
password="${secret_value}"


if [[ "$GATEWAY_TYPE" == "Onpremises" ]]; then
  # Get the list of gateways
  log_info "Getting the list of gateways..."
  gateways_json="$(curl -sS -H "${auth_header[@]}" -H "${content_type[@]}" "https://api.powerbi.com/v1.0/myorg/gateways")"

  # Determine if on-premises gateway is present
  gateway_json="$(printf '%s' "${gateways_json}" | jq -r --arg id "${gateway_id}" '.value[] | select(.id==$id)')"

  if [[ -z "${gateway_json}" || "${gateway_json}" == "null" ]]; then
    log_error "The gateway with ID=${gatewayId} has not been found."
    exit 1
  fi

  # On-premises gateway found - use encrypted credentials
  log_info "Encrypting credentials using the gateway public key..."
  gateway_exponent_b64="$(printf '%s' "${gateway_json}" | jq -r '.publicKey.exponent')"
  gateway_modulus_b64="$(printf '%s' "${gateway_json}" | jq -r '.publicKey.modulus')"
  #log_info "Gateway public key exponent (Base64): ${gateway_exponent_b64}"
  #log_info "Gateway public key modulus (Base64): ${gateway_modulus_b64}"

  # Instantiate the credentials encryptor service (bash version)
  serialized_credentials="{'credentialData':[{'name':'username', 'value':'${username}'},{'name':'password', 'value':'${password}'}]}"
  encrypted_credentials="$("${SCRIPT_DIR}/encrypt_credential_service.sh" "${gateway_exponent_b64}" "${gateway_modulus_b64}" "${serialized_credentials}")"

  body_json="$(jq -n --arg enc "${encrypted_credentials}" '{credentialDetails:{credentialType:"Basic", credentials:$enc, encryptedConnection:"Encrypted", encryptionAlgorithm:"RSA-OAEP", privacyLevel:"Private"}}')"
else
  # No gateway or managed VNET gateway - use non-encrypted credentials
  cred_str="$(jq -cn --arg u "${username}" --arg p "${password}" '{credentialData:[{name:"username",value:$u},{name:"password",value:$p}]}' | jq -c .)"
  body_json="$(jq -n --arg cs "${cred_str}" '{credentialDetails:{credentialType:"Basic", credentials:$cs, encryptedConnection:"Encrypted", encryptionAlgorithm:"None", privacyLevel:"Organizational"}}')"
fi


# Update the datasource with the new credentials
log_info "Updating the datasource credentials, gatewayId=${gateway_id}, datasourceId=${datasource_id}..."
curl -sS -X PATCH -H "${auth_header[@]}" -H "${content_type[@]}" -d "${body_json}" "https://api.powerbi.com/v1.0/myorg/gateways/${gateway_id}/datasources/${datasource_id}" >/dev/null


# Trigger a dataset refresh
if [[ "${REFRESH_DATASET}" == true ]]; then
  log_info "Triggering dataset ${DATASET_NAME} refresh..."
  curl -sS -X POST -H "${auth_header[@]}" -H "${content_type[@]}" -d '{}' "https://api.powerbi.com/v1.0/myorg/groups/${workspace_id}/datasets/${dataset_id}/refreshes" >/dev/null || true
else
  log_info "Dataset refresh skipped."
fi

log_info "Execution completed"


