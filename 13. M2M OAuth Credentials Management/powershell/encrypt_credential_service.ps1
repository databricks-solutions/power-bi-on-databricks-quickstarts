<#
    .SYNOPSIS
    Encrypts credentials for Power BI and Databricks integration using RSA encryption.
    .DESCRIPTION
    This script provides functionality to encrypt credentials using RSA public key encryption. The code is based on https://github.com/microsoft/PowerBI-CSharp
    .EXAMPLE
    PS> & './Update-M2M-OAuth-Credentials.ps1' -ServicePrincipal "MyServicePrincipal" -WarehouseId "44ff20e73e461e56" -Workspace "SPN-rotation-test" -Dataset "tpch" -Lifetime 60 -RefreshDataset
    .LICENSE
    This code is licensed under the MIT License.
    .LINK
    None
#>

using namespace System
using namespace System.Text
using namespace System.Security.Cryptography

# Based on the Power BI C# SDK implementation - https://github.com/microsoft/PowerBI-CSharp/blob/master/sdk/PowerBI.Api/Extensions/AuthenticatedEncryption.cs
class EncryptCredentialService {
    [int] $MODULUS_SIZE = 128
    [hashtable] $PublicKey

    EncryptCredentialService([hashtable] $publicKey) {
        if (-not $publicKey) {
            throw [System.ArgumentException] "public_key is required"
        }
        if (-not $publicKey.ContainsKey("exponent") -or [string]::IsNullOrEmpty($publicKey["exponent"])) {
            throw [System.ArgumentException] "public_key['exponent'] is required"
        }
        if (-not $publicKey.ContainsKey("modulus") -or [string]::IsNullOrEmpty($publicKey["modulus"])) {
            throw [System.ArgumentException] "public_key['modulus'] is required"
        }
        $this.PublicKey = $publicKey
    }

    [string] EncodeCredentials([string] $credentialsData) {
        if ([string]::IsNullOrEmpty($credentialsData)) {
            throw [System.ArgumentException] "credentials data required"
        }

        # Convert credentials string to bytes
        $plainTextBytes = [System.Text.Encoding]::UTF8.GetBytes($credentialsData)

        # Decode Base64 modulus and exponent
        $modulusBytes = [System.Convert]::FromBase64String($this.PublicKey["modulus"])
        $exponentBytes = [System.Convert]::FromBase64String($this.PublicKey["exponent"])

        # Instantiate helpers
        $asymmetric1024Helper = [Asymmetric1024KeyEncryptionHelper]::new()
        $asymmetricHigherHelper = [AsymmetricHigherKeyEncryptionHelper]::new()

        if ($modulusBytes.Length -eq $this.MODULUS_SIZE) {
            return $asymmetric1024Helper.Encrypt($plainTextBytes, $modulusBytes, $exponentBytes)
        }
        else {
            return $asymmetricHigherHelper.Encrypt($plainTextBytes, $modulusBytes, $exponentBytes)
        }
    }
}


# Based on the Power BI C# SDK implementation - https://github.com/microsoft/PowerBI-CSharp/blob/master/sdk/PowerBI.Api/Extensions/Asymmetric1024KeyEncryptionHelper.cs
class Asymmetric1024KeyEncryptionHelper {
    [int] $SEGMENT_LENGTH = 60
    [int] $ENCRYPTED_LENGTH = 128
    [int] $MAX_ATTEMPTS = 3

    Asymmetric1024KeyEncryptionHelper() {}

    [string] Encrypt([byte[]] $plainTextBytes, [byte[]] $modulusBytes, [byte[]] $exponentBytes) {
        if (-not $plainTextBytes -or $plainTextBytes.Length -eq 0) {
            throw "Plain text bytes cannot be empty"
        }

        $hasIncompleteSegment = ($plainTextBytes.Length % $this.SEGMENT_LENGTH) -ne 0
        $segmentNumber = [math]::Ceiling($plainTextBytes.Length / $this.SEGMENT_LENGTH)

        # Prepare array for encrypted bytes
        $encryptedBytes = New-Object byte[] ($segmentNumber * $this.ENCRYPTED_LENGTH)

        for ($i = 0; $i -lt $segmentNumber; $i++) {
            if ($i -eq $segmentNumber - 1 -and $hasIncompleteSegment) {
                $lengthToCopy = $plainTextBytes.Length % $this.SEGMENT_LENGTH
            } else {
                $lengthToCopy = $this.SEGMENT_LENGTH
            }

            $segment = New-Object byte[] $lengthToCopy
            [Array]::Copy($plainTextBytes, $i * $this.SEGMENT_LENGTH, $segment, 0, $lengthToCopy)

            $segmentEncrypted = $this.EncryptSegment($modulusBytes, $exponentBytes, $segment)

            [Array]::Copy($segmentEncrypted, 0, $encryptedBytes, $i * $this.ENCRYPTED_LENGTH, $segmentEncrypted.Length)
        }

        return [Convert]::ToBase64String($encryptedBytes)
    }

    [byte[]] EncryptSegment([byte[]] $modulusBytes, [byte[]] $exponentBytes, [byte[]] $data) {
        if (-not $data -or $data.Length -eq 0) {
            throw "Data is null or empty"
        }

        for ($attempt = 0; $attempt -lt $this.MAX_ATTEMPTS; $attempt++) {
            try {
                # Build RSA parameters
                $rsaParams = [RSAParameters]::new()
                $rsaParams.Modulus  = $modulusBytes
                $rsaParams.Exponent = $exponentBytes

                $rsa = [RSA]::Create()
                $rsa.ImportParameters($rsaParams)

                # Encrypt with RSA OAEP SHA256
                $encryptedBytes = $rsa.Encrypt(
                    $data,
                    [RSAEncryptionPadding]::OaepSHA256
                )

                $rsa.Dispose()
                return $encryptedBytes
            }
            catch {
                Start-Sleep -Milliseconds 50
                if ($attempt -eq $this.MAX_ATTEMPTS - 1) {
                    throw $_.Exception
                }
            }
        }

        throw "Invalid Operation"
    }
}


# Based on the Power BI C# SDK implementation - https://github.com/microsoft/PowerBI-CSharp/blob/master/sdk/PowerBI.Api/Extensions/AsymmetricHigherKeyEncryptionHelper.cs
class AsymmetricHigherKeyEncryptionHelper {
    [int] $KEY_LENGTHS_PREFIX = 2
    [int] $HMAC_KEY_SIZE_BYTES = 64
    [int] $AES_KEY_SIZE_BYTES  = 32
    [byte] $KEY_LENGTH_32 = 0
    [byte] $KEY_LENGTH_64 = 1

    AsymmetricHigherKeyEncryptionHelper() {}

    [string] Encrypt([byte[]] $plainTextBytes, [byte[]] $modulusBytes, [byte[]] $exponentBytes) {
        if (-not $plainTextBytes -or $plainTextBytes.Length -eq 0) {
            throw "Plain text bytes cannot be empty"
        }

        # Generate ephemeral random keys
        $keyEnc = New-Object byte[] $this.AES_KEY_SIZE_BYTES
        $keyMac = New-Object byte[] $this.HMAC_KEY_SIZE_BYTES
        [Security.Cryptography.RandomNumberGenerator]::Fill($keyEnc)
        [Security.Cryptography.RandomNumberGenerator]::Fill($keyMac)

        # Symmetric encryption (AuthenticatedEncryption helper)
        $authenticatedEncryption = [AuthenticatedEncryption]::new()
        $cipherText = $authenticatedEncryption.Encrypt($keyEnc, $keyMac, $plainTextBytes)

        # Build byte array for key material: [lenEnc, lenMac, keyEnc, keyMac]
        $keysLength = $this.AES_KEY_SIZE_BYTES + $this.HMAC_KEY_SIZE_BYTES + $this.KEY_LENGTHS_PREFIX
        $keys = New-Object byte[] $keysLength
        $keys[0] = [byte]$this.KEY_LENGTH_32
        $keys[1] = [byte]$this.KEY_LENGTH_64
        [Array]::Copy($keyEnc, 0, $keys, 2, $keyEnc.Length)
        [Array]::Copy($keyMac, 0, $keys, 2 + $keyEnc.Length, $keyMac.Length)

        # Import modulus/exponent as public RSA key
        $rsaParams = [RSAParameters]::new()
        $rsaParams.Modulus  = $modulusBytes
        $rsaParams.Exponent = $exponentBytes

        $rsa = [RSA]::Create()
        $rsa.ImportParameters($rsaParams)

        # RSA encrypt ephemeral keys with OAEP-SHA256
        $encryptedBytes = $rsa.Encrypt(
            $keys,
            [RSAEncryptionPadding]::OaepSHA256
        )
        $rsa.Dispose()

        # Return concatenated Base64 (RSA block + AES/HMAC ciphertext)
        $rsaPart    = [Convert]::ToBase64String($encryptedBytes)
        $cipherPart = [Convert]::ToBase64String($cipherText)
        return $rsaPart + $cipherPart
    }
}



class AuthenticatedEncryption {
    [byte] $Aes256CbcPkcs7 = 0
    [byte] $HMACSHA256     = 0
    [byte[]] $AlgorithmChoices

    AuthenticatedEncryption() {
        $this.AlgorithmChoices = @($this.Aes256CbcPkcs7, $this.HMACSHA256)
    }

    [byte[]] Encrypt([byte[]] $keyEnc, [byte[]] $keyMac, [byte[]] $message) {
        # Validate key sizes
        if ($null -eq $keyEnc -or $keyEnc.Length -lt 32) {
            throw [System.ArgumentException] "Encryption Key must be at least 256 bits (32 bytes)"
        }
        if ($null -eq $keyMac -or $keyMac.Length -lt 32) {
            throw [System.ArgumentException] "Mac Key must be at least 256 bits (32 bytes)"
        }
        if (-not $message -or $message.Length -eq 0) {
            throw [System.ArgumentException] "Credentials cannot be null"
        }

        # Generate random IV (16 bytes for AES CBC)
        $iv = New-Object byte[] 16
        [RandomNumberGenerator]::Fill($iv)

        # AES CBC with PKCS7 padding
        $aes = [Aes]::Create()
        $aes.KeySize = 256
        $aes.Key = $keyEnc
        $aes.IV = $iv
        $aes.Mode = [CipherMode]::CBC
        $aes.Padding = [PaddingMode]::PKCS7

        $encryptor = $aes.CreateEncryptor()
        $cipherText = $encryptor.TransformFinalBlock($message, 0, $message.Length)
        $aes.Dispose()

        # --- Build Tag Data for HMAC: Algorithm choices + IV + CipherText ---
        $tagData = New-Object byte[] ($this.AlgorithmChoices.Length + $iv.Length + $cipherText.Length)
        [Array]::Copy($this.AlgorithmChoices, 0, $tagData, 0, $this.AlgorithmChoices.Length)
        [Array]::Copy($iv, 0, $tagData, $this.AlgorithmChoices.Length, $iv.Length)
        [Array]::Copy($cipherText, 0, $tagData, $this.AlgorithmChoices.Length + $iv.Length, $cipherText.Length)

        # HMAC-SHA256 authentication
        $hmac = [HMACSHA256]::new($keyMac)
        $mac = $hmac.ComputeHash($tagData)
        $hmac.Dispose()

        # --- Build final output: Algorithm choices + MAC + IV + CipherText ---
        $output = New-Object byte[] ($this.AlgorithmChoices.Length + $mac.Length + $iv.Length + $cipherText.Length)
        $offset = 0

        [Array]::Copy($this.AlgorithmChoices, 0, $output, $offset, $this.AlgorithmChoices.Length)
        $offset += $this.AlgorithmChoices.Length

        [Array]::Copy($mac, 0, $output, $offset, $mac.Length)
        $offset += $mac.Length

        [Array]::Copy($iv, 0, $output, $offset, $iv.Length)
        $offset += $iv.Length

        [Array]::Copy($cipherText, 0, $output, $offset, $cipherText.Length)
        $offset += $cipherText.Length

        return $output
    }
}
