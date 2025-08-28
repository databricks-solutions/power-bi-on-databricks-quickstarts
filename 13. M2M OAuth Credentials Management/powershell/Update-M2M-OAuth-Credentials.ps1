<#
    .SYNOPSIS
    This script rotates the Databricks Service Principal credentials for Power BI and Databricks integration.
    .DESCRIPTION
    This script rotates the Databricks Service Principal credentials for Power BI and Databricks integration, updating the SQL Warehouse permissions and dataset credentials.
    .PARAMETER ServicePrincipal
    The name of the Databricks Service Principal to create or update.
    .PARAMETER WarehouseId
    The SQL Warehouse ID to be used by the Databricks Service Principal.
    .PARAMETER Workspace
    The name of the Power BI workspace.
    .PARAMETER Dataset
    The name of the Power BI dataset.
    .PARAMETER GatewayType
    The type of the gateway used by the Power BI semantic model. Valid values are "NoGateway", "VNET", and "Onpremises". Default is "Onpremises".
    .PARAMETER Lifetime
    The secret lifetime in seconds. Default is 604800 seconds (7 days).
    .PARAMETER RefreshDataset
    If specified, the dataset will be refreshed after updating the credentials.
    .PARAMETER SecretScope
    The name of the Databricks secret scope where Entra ID Service Principal details are stored.
    .PARAMETER ClientIdSecret
    The name of the Databricks secret scope where Entra ID Service Principal Client ID is stored.
    .PARAMETER SecretSecret
    The name of the Databricks secret scope where Entra ID Service Principal Secret is stored.
    .PARAMETER TenantIdSecret
    The name of the Databricks secret scope where Entra ID Service Principal Tenant ID is stored.
    .PARAMETER Profile
    The name of the Databricks CLI profile to use. Default is "DEFAULT".
    .OUTPUTS
    None
    .EXAMPLE
    PS> ./Update-M2M-OAuth-Credentials.ps1' `
            -ServicePrincipal "MySPN" `
            -WarehouseId "44ff20e73e461e56" `
            -Workspace "SPN-rotation-test" `
            -Dataset "tpch" `
            -GatewayType "NoGateway" `
            -Lifetime 60 `
            -RefreshDataset `
            -SecretScope "powerbi_credentials" `
            -ClientIdSecret "powerbi_client_id" `
            -SecretSecret "powerbi_client_secret" `
            -TenantIdSecret "powerbi_tenant_id"
    .LINK
    https://github.com/databricks-solutions/power-bi-on-databricks-quickstarts
#>

param(
    [Parameter(Mandatory=$true, HelpMessage = "Enter the name of the Service Principal.")]
    [string]$ServicePrincipal,                          # Name of the Service Principal to create or update

    [Parameter(Mandatory=$true, HelpMessage = "Enter the SQL Warehouse ID.")]
    [string]$WarehouseId,                               # SQL Warehouse ID to be used by the Service Principal - d07f8713ff62fff5, a5ad4687dadae274, 44ff20e73e461e56

    [Parameter(Mandatory=$true, HelpMessage = "Enter the name of the Power BI workspace.")]
    [string]$Workspace,                                 # Power BI Workspace name

    [Parameter(Mandatory=$true, HelpMessage = "Enter the name of the Power BI semantic model (dataset).")]
    [string]$Dataset,                                   # Power BI Dataset name - tpch-vnet-gateway, tpch-no-gateway, tpch-onprem-gateway

    [Parameter(Mandatory=$false, HelpMessage = "Enter the type of the gateway used by the Power BI semantic model.")]
    [ValidateSet("NoGateway", "VNET", "Onpremises")]
    [string]$GatewayType = "NoGateway",                 # Gateway type being used for the Power BI dataset - NoGateway, VNET, Onpremises

    [Parameter(Mandatory=$false, HelpMessage = "Enter the lifetime (in seconds) of the secret.")]
    [int]$Lifetime = 604800,                            # Secret lifetime in seconds, default is 604800 seconds

    [Parameter(Mandatory=$false, HelpMessage = "Specify the flag if the semantic model shall be refreshed after updating the credentials.")]
    [switch]$RefreshDataset,                            # If specified, the dataset will be refreshed after updating the credentials

    [Parameter(Mandatory=$true, HelpMessage = "Enter the name of Databricks secret scope where Entra ID Service Principal details are stored.")]
    [string]$SecretScope,                               # Databricks secret scope, where Entra ID Service Principal details are stored

    [Parameter(Mandatory=$true, HelpMessage = "Enter the name of Databricks secret scope where Entra ID Service Principal Client ID is stored.")]
    [string]$ClientIdSecret,                            # Databricks secret scope, where Entra ID Service Principal Client ID is stored

    [Parameter(Mandatory=$true, HelpMessage = "Enter the name of Databricks secret scope where Entra ID Service Principal Secret is stored.")]
    [string]$SecretSecret,                              # Databricks secret scope, where Entra ID Service Principal Secret is stored

    [Parameter(Mandatory=$true, HelpMessage = "Enter the name of Databricks secret scope where Entra ID Service Principal Tenant ID is stored.")]
    [string]$TenantIdSecret,                            # Databricks secret scope, where Entra ID Service Principal Tenant ID is stored

    [Parameter(Mandatory=$false, HelpMessage = "Enter the name of Databricks CLI profile.")]
    [string]$Profile = "DEFAULT"                        # Databricks CLI profile to use, default is "DEFAULT"

)

$ErrorActionPreference = "Stop"

# ========================== Databricks Service Principal management ========================

# Check if the Databricks CLI is installed
if (-not (Get-Command databricks -ErrorAction SilentlyContinue)) {
  Write-Error "Databricks CLI is not installed. Please install it and try again. See more details here - https://docs.databricks.com/aws/en/dev-tools/cli/install."
  exit 1
}

function Compare-Version($v1, $v2) {
    $a = $v1.Split('.')
    $b = $v2.Split('.')
    for ($i=0; $i -lt $a.Length; $i++) {
        if ([int]$a[$i] -lt [int]$b[$i]) { return -1 }
        elseif ([int]$a[$i] -gt [int]$b[$i]) { return 1 }
    }
    return 0
}

# Check if the Databricks CLI version is below the required version
$version = databricks -v | Select-String -Pattern '\d+\.\d+\.\d+' | ForEach-Object { $_.Matches[0].Value }
$required = '0.264.2'
if ((Compare-Version $version $required) -eq -1) {
    Write-Error "Databricks CLI version is below $required. Please update it to continue."
    exit 1
} else {
    Write-Host "Databricks CLI version is $version (>= $required). Proceeding..."
}


# Check if the Databricks Service Principal already exists
Write-Host "Checking if Service Principal $ServicePrincipal exists..."
$listSpnCommand = "databricks service-principals list --filter ""displayName eq {0}"" --output json --profile {1}" -f $ServicePrincipal, $Profile
$spnInfo = Invoke-Expression $listSpnCommand | ConvertFrom-Json


# If the Databricks Service Principal does not exist, create it
if ($null -eq $spnInfo) {
    Write-Host "Creating Service Principal $ServicePrincipal..."
    $createSpnCommand = "databricks service-principals create --display-name ""{0}"" --output json --profile {1}" -f $ServicePrincipal, $Profile
    $spnInfo = Invoke-Expression $createSpnCommand | ConvertFrom-Json
}
Write-Host "Service Principal info: id=$($spnInfo.id) appId=$($spnInfo.applicationId)"


# Check if the Databricks Service Principal has already 5 secrets (maximum allowed)
Write-Host "Getting the list of secret..."
$listSecretsCommand = "databricks service-principal-secrets-proxy list {0} --output json --profile {1}" -f $spnInfo.id, $Profile
$secretsList = Invoke-Expression $listSecretsCommand | ConvertFrom-Json
Write-Host "Secrets count: $($secretsList.Count)"
if ($secretsList.Count -eq 5) {
    Write-Error "Service Principal $ServicePrincipal has already 5 secrets. Creating more than 5 secrets is not supported. Please delete some of the secrets to continue."
    exit 1
}


# Create a new secret for the Databricks Service Principal
Write-Host "Creating Secret..."
$createSecretCommand = "databricks service-principal-secrets-proxy create {0} --lifetime ""{1}s"" --output json --profile {2}" -f $spnInfo.id, $lifetime, $Profile
$secretInfo = Invoke-Expression $createSecretCommand | ConvertFrom-Json


# Grant Databricks Service Principal CAN USE permissions on the SQL Warehouse
Write-Host "Granting Service Principal $ServicePrincipal CAN USE permission on SQL Warehouse $WarehouseId..."
$persmisisons = '{"access_control_list":[{"service_principal_name":"' + $spnInfo.applicationId + '","permission_level":"CAN_USE"}]}'
$grantPermissionCommand = "databricks warehouses set-permissions {0} --json '{1}' --profile {2}" -f $WarehouseId, $persmisisons, $Profile
Invoke-Expression $grantPermissionCommand | Out-Null



### ========================= Power BI Integration ======================== ###

# Connect to Power BI Service and get the access token
#Connect-PowerBIServiceAccount
#$accessToken = Get-PowerBIAccessToken -AsString
#$headers = @{ "Authorization" = "$accessToken" } 

# Get the Entra ID Service Principal details from Databricks secrets
Write-Host "Getting Entra ID Service Principal..."
$powerbiSpnCommand = "databricks secrets get-secret ""{0}"" ""{1}"" --profile {2} | jq -r .value | base64 --decode" -f $SecretScope, $ClientIdSecret, $Profile
$powerbiClientId = Invoke-Expression $powerbiSpnCommand
$powerbiSpnCommand = "databricks secrets get-secret ""{0}"" ""{1}"" --profile {2} | jq -r .value | base64 --decode" -f $SecretScope, $SecretSecret, $Profile
$powerbiClientSecret = Invoke-Expression $powerbiSpnCommand
$powerbiSpnCommand = "databricks secrets get-secret ""{0}"" ""{1}"" --profile {2} | jq -r .value | base64 --decode" -f $SecretScope, $TenantIdSecret, $Profile
$powerbiTenantId = Invoke-Expression $powerbiSpnCommand
Write-Host "Entra ID Service Principal info: appId=$powerbiClientId tenantId=$powerbiTenantId"


# Get the Power BI access token using the Entra ID Service Principal
Write-Host "Getting Power BI access token..."
$body = @{
    client_id     = $powerbiClientId
    client_secret = $powerbiClientSecret
    scope         = "https://analysis.windows.net/powerbi/api/.default"
    grant_type    = "client_credentials"
}
$response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$powerbiTenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $body
$accessToken = $response.access_token
$headers = @{ "Authorization" = "Bearer $accessToken" } 
$contentType = "application/json"


# Get the list of Power BI workspaces
Write-Host "Getting the list of workspaces..."
$groupsUrl = "https://api.powerbi.com/v1.0/myorg/groups"
$groups = Invoke-RestMethod -Uri $groupsUrl -Method Get -Header $headers -ContentType $contentType
# Find the workspace with the specified name
$workspaceId = $groups.value | Where-Object { $_.name -eq $Workspace } | Select-Object -First 1 -ExpandProperty id
if ($null -eq $workspaceId) {
    Write-Error "The workspace $Workspace has not been found."
    exit 1
}


# Get the list of datasets in the Power BI workspace
Write-Host "Getting the list of datasets..."
$datasetsUrl = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/datasets"
$datasets = Invoke-RestMethod -Uri $datasetsUrl -Method Get -Header $headers -ContentType $contentType
# Find the dataset with the specified name
$datasetId = $datasets.value | Where-Object { $_.name -eq $Dataset } | Select-Object -First 1 -ExpandProperty id
if ($null -eq $datasetId) {
    Write-Error "The dataset $Dataset has not been found."
    exit 1
}


# Take over the Power BI dataset to be able to update the credentials
if ($GatewayType -eq "NoGateway") {
    Write-Host "Taking over the dataset..."
    $takeoverUrl = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/Default.TakeOver"
    Invoke-RestMethod -Uri $takeoverUrl -Method Post -Header $headers -ContentType $contentType
}


# Get the list of datasources for the Power BI dataset
Write-Host "Getting the list of datasources..."
$datasouresUrl = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/datasets/$datasetId/datasources"
$dataSources = Invoke-RestMethod -Uri $datasouresUrl -Method Get -Header $headers -ContentType $contentType
# Find the datasource with the kind 'Databricks*'
$datasource = $datasources.value | Where-Object { $_.ConnectionDetails.kind -like 'Databricks*' } | Select-Object -First 1
if ($null -eq $datasource) {
    Write-Error "Databricks datasource has not been found."
    exit 1
}
$datasourceId = $datasource.datasourceId
$gatewayId = $datasource.gatewayId


$username = $spnInfo.applicationId 
$password = $secretInfo.secret     

if ($GatewayType -eq "Onpremises") {
    # Get the list of gateways
    Write-Host "Getting the list of gateways..."
    $gatewaysUrl = "https://api.powerbi.com/v1.0/myorg/gateways"
    $gateways = Invoke-RestMethod -Uri $gatewaysUrl -Method Get -Header $headers -ContentType $contentType

    # Find the gateway with the specified ID
    $gateway = $gateways.value | Where-Object { $_.id -eq $gatewayId } | Select-Object -First 1
    if ($null -eq $gateway) {
        Write-Error "The gateway with ID $gatewayId has not been found."
        exit 1
    }

    # Onpremises gateway found - use encrypted credentials
    Write-Host "Encrypting credentials using the gateway public key..."
    
    # Get gateway public key
    $gatewayPublicKey = $gateway.publicKey
    $gatewayExponent = $gatewayPublicKey.exponent
    $gatewayModulus = $gatewayPublicKey.modulus

    Import-Module .\encrypt_credential_service.ps1 -Force

    $public_key = @{
        'exponent' = $gatewayExponent
        'modulus'  = $gatewayModulus
    }

    # Instantiate the credentials encryptor service
    $enc = [EncryptCredentialService]::new($public_key)

    # Encrypt the credentials using the service
    $serialized_credentials = "{'credentialData':[{'name':'username', 'value':'$username'},{'name':'password', 'value':'$password'}]}"
    $encrypted_credentials = $enc.EncodeCredentials($serialized_credentials)

    $body = @{
        credentialDetails = @{
            credentialType      = 'Basic'
            credentials         = $encrypted_credentials
            encryptedConnection = 'Encrypted'
            encryptionAlgorithm = 'RSA-OAEP'
            privacyLevel        = 'Private'
        }
    } | ConvertTo-Json -Depth 6
} else {
    # No gateway or managed VNET gateway - use non-encrypted credentials
    $body = @{
        credentialDetails = @{
            credentialType      = 'Basic'
            credentials = @{
                credentialData = @(
                    @{ name = 'username'; value = $username },
                    @{ name = 'password'; value = $password }
                )
            } | ConvertTo-Json
            encryptedConnection = 'Encrypted'
            encryptionAlgorithm = 'None'
            privacyLevel        = 'Organizational'
        }
    } | ConvertTo-Json -Depth 6
}


# Update the datasource with the new credentials
Write-Host "Updating the datasource credentials, gatewayId=$gatewayId , datasourceId=$datasourceId..." 
$datasourePatchUrl = "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources/$datasourceId"
Invoke-RestMethod -Method Patch -Uri $datasourePatchUrl -Body $body -Headers $headers -ContentType $contentType


# Trigger a dataset refresh
if ($RefreshDataset) {
    Write-Host "Triggering dataset $Dataset refresh..."
    $datasetRefreshUrl = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/refreshes"
    Invoke-RestMethod -Method Post -Uri $datasetRefreshUrl -Headers $headers -WarningAction Ignore
} else {
    Write-Host "Dataset refresh skipped."
}

Write-Host "Execution completed"