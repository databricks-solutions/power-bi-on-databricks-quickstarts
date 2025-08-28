# M2M OAuth Credentials Management - PowerShell


## Prerequisites

Before you begin, ensure you have the following:

- [Databricks account](https://databricks.com/), access to a Databricks workspace, and Databricks SQL Warehouse
    - [Permissions](https://docs.databricks.com/aws/en/admin/users-groups/service-principals#who-can-manage-and-use-service-principals) to create and manage service principals, either **Account admins** or **Workspace admins**. 
- [Databricks CLI](https://docs.databricks.com/aws/en/dev-tools/cli/), version 0.264 or above
    - [Databricks CLI](https://docs.databricks.com/aws/en/dev-tools/cli/) must be configured for the target Databricks Workspace and authentication method using ``databricks configure`` command.
- [PowerShell Core](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
- [Microsoft Entra ID Service Principal](https://learn.microsoft.com/en-us/entra/identity-platform/app-objects-and-service-principals) which has permissions to access target Power BI workspace, dataset, gateway
    - `ClientID`, `Secret`, and `TenantID` must be stored as [Databricks secrets](https://docs.databricks.com/aws/en/security/secrets/)
    - Entra ID Service Principal must have permisions to change settings of the dataset and the gateway (if gateway is in use)

> [!NOTE]
> This code utilizes the [Power BI REST API](https://learn.microsoft.com/en-us/rest/api/power-bi/) as described in the official Power BI REST API documentation and does not require installation of additional packages or libraries.


## Parameters

| **Parameter**           | **Purpose**                                                                                   |
| ----------------------- | --------------------------------------------------------------------------------------------- |
| `ServicePrincipal`      | The name of the Service Principal to be created or updated                                    |
| `WarehouseId`           | The SQL Warehouse ID to be used by the Service Principal                                      |
| `Workspace`             | The name of the Power BI Workspace                                                            |
| `Dataset`               | The name of the Power BI dataset (semantic model)                                             |
| `GatewayType`           | The type of gateway used by Power BI dataset - `NoGateway`, `Onpremises`, `VNET`              |
| `Lifetime`              | The lifetime of the secret in seconds                                                         |
| `RefreshDataset`        | The flag indicating if the dataset shall be refreshed                                         |
| `SecretScope`           | The name of the Databricks secret scope where Entra ID Service Principal details are stored   |
| `ClientIdSecret`        | The name of the Databricks secret scope where Entra ID Service Principal Client ID is stored  |
| `SecretSecret`          | The name of the Databricks secret scope where Entra ID Service Principal Secret is stored     |
| `TenantIdSecret`        | The name of the Databricks secret scope where Entra ID Service Principal Tenant ID is stored  |
| `Profile`               | The name of Databricks CLI profile to be used, `DEFAULT` if not specified                     |


## Syntax
```powershell
./Update-M2M-OAuth-Credentials.ps1
    -ServicePrincipal <String>
    -WarehouseId <String>
    -Workspace <String>
    -Dataset <String> 
    -GatewayType <String>
    -Lifetime <Int32>
    -RefreshDataset
    -SecretScope <String>
    -ClientIdSecret <String>
    -SecretSecret <String>
    -TenantIdSecret <String>
    -Profile <String>
```


## Example
```powershell
./Update-M2M-OAuth-Credentials.ps1 `
    -ServicePrincipal "MyServicePrincipal" `
    -WarehouseId "a5ad4687dadae274" `
    -Workspace "SPN-rotation-test" `
    -Dataset "tpch-no-gateway" `
    -Lifetime 600 `
    -GatewayType "NoGateway" `
    -RefreshDataset
    -SecretScope "powerbi_credentials" `
    -ClientIdSecret "powerbi_client_id" `
    -SecretSecret "powerbi_client_secret" `
    -TenantIdSecret "powerbi_tenant_id" `
    -RefreshDataset
```

```output
Databricks CLI version is 0.264.2 (>= 0.264.2). Proceeding...
Checking if Service Principal MyServicePrincipal exists...
Service Principal info: id=140777925918067 appId=d596a852-2b6c-45bf-98ca-86f542dd5ef3
Getting the list of secret...
Secrets count: 0
Creating Secret...
Granting Service Principal MyServicePrincipal CAN USE permission on SQL Warehouse a5ad4687dadae274...
Getting Entra ID Service Principal...
Entra ID Service Principal info: appId=034be9fb-f1b5-4dd4-b666-25e8166a51c4 tenantId=9f37a392-f0ae-4280-9796-f1864a10effc
Getting Power BI access token...
Getting the list of workspaces...
Getting the list of datasets...
Taking over the dataset...
Getting the list of datasources...
Updating the datasource credentials, gatewayId=c8f401ed-83dd-4bba-be45-4635d32099b1 , datasourceId=0390f438-9801-485d-95f3-2c5fccf4369e...
Triggering dataset tpch-no-gateway refresh...
Execution completed
```

## Script walkthrough

> [!IMPORTANT]
> Microsoft does not officially support VNET managed gateways via the [Power BI REST API](https://learn.microsoft.com/en-us/rest/api/power-bi/), and the functionality described here is not guaranteed. Future changes by Microsoft to the [Power BI REST API](https://learn.microsoft.com/en-us/rest/api/power-bi/) or VNET managed gateway behavior may impact compatibility or performance of this solution. Use at your own risk.


#### 1. Validate Databricks CLI installation

``` powershell
if (-not (Get-Command databricks -ErrorAction SilentlyContinue)) {
  Write-Error "Databricks CLI is not installed. Please install it and try again. See more details here - https://docs.databricks.com/aws/en/dev-tools/cli/install."
  exit 1
}
```


#### 2. Validate Databricks CLI verion

``` powershell
$version = databricks -v | Select-String -Pattern '\d+\.\d+\.\d+' | ForEach-Object { $_.Matches[0].Value }
$required = '0.264.2'
if ((Compare-Version $version $required) -eq -1) {
    Write-Error "Databricks CLI version is below $required. Please update it to continue."
    exit 1
} else {
    Write-Host "Databricks CLI version is $version (>= $required). Proceeding..."
}
```


#### 3. Check if the Service Principal exists

```powershell
Write-Host "Checking if Service Principal $ServicePrincipal exists..."
$listSpnCommand = "databricks service-principals list --filter ""displayName eq {0}"" --output json --profile {1}" -f $ServicePrincipal, $Profile
$spnInfo = Invoke-Expression $listSpnCommand | ConvertFrom-Json
```


#### 4. Create the Service Principal if it does not exist

```powershell
if ($null -eq $spnInfo) {
    Write-Host "Creating Service Principal $ServicePrincipal..."
    $createSpnCommand = "databricks service-principals create --display-name ""{0}"" --output json --profile {1}" -f $ServicePrincipal, $Profile
    $spnInfo = Invoke-Expression $createSpnCommand | ConvertFrom-Json
}
Write-Host "Service Principal info: id=$($spnInfo.id) appId=$($spnInfo.applicationId)"
```


#### 5. Validate the Service Principal secrets limit (max 5 secrets allowed)

```powershell
Write-Host "Getting the list of secret..."
$listSecretsCommand = "databricks service-principal-secrets-proxy list {0} --output json --profile {1}" -f $spnInfo.id, $Profile
$secretsList = Invoke-Expression $listSecretsCommand | ConvertFrom-Json
Write-Host "Secrets count: $($secretsList.Count)"
if ($secretsList.Count -eq 5) {
    Write-Error "Service Principal $ServicePrincipal has already 5 secrets. Creating more than 5 secrets is not supported. Please delete some of the secrets to continue."
    exit 1
}
```


#### 6. Create a new secret for the Service Principal

```powershell
Write-Host "Creating Secret..."
$createSecretCommand = "databricks service-principal-secrets-proxy create {0} --lifetime ""{1}s"" --output json --profile {2}" -f $spnInfo.id, $lifetime, $Profile
$secretInfo = Invoke-Expression $createSecretCommand | ConvertFrom-Json
Write-Host "Secret info: $secretInfo"
```


#### 7. Grant Service Principal CAN USE permission on the SQL Warehouse

```powershell
Write-Host "Granting Service Principal $ServicePrincipal CAN USE permission on SQL Warehouse $WarehouseId..."
$persmisisons = '{"access_control_list":[{"service_principal_name":"' + $spnInfo.applicationId + '","permission_level":"CAN_USE"}]}'
$grantPermissionCommand = "databricks warehouses set-permissions {0} --json '{1}' --profile {2}" -f $WarehouseId, $persmisisons, $Profile
Invoke-Expression $grantPermissionCommand | Out-Null
```


#### 8. Retrieve Power BI credentials from Databricks secrets

```powershell
Write-Host "Getting Entra ID Service Principal..."
$powerbiSpnCommand = "databricks secrets get-secret ""{0}"" ""{1}"" --profile {2} | jq -r .value | base64 --decode" -f $scope, $powerBiClientIdSecretName, $Profile
$powerbiClientId = Invoke-Expression $powerbiSpnCommand
$powerbiSpnCommand = "databricks secrets get-secret ""{0}"" ""{1}"" --profile {2} | jq -r .value | base64 --decode" -f $scope, $powerBiSecretSecretName, $Profile
$powerbiClientSecret = Invoke-Expression $powerbiSpnCommand
$powerbiSpnCommand = "databricks secrets get-secret ""{0}"" ""{1}"" --profile {2} | jq -r .value | base64 --decode" -f $scope, $powerBiTenantIdSecretName, $Profile
$powerbiTenantId = Invoke-Expression $powerbiSpnCommand
Write-Host "Entra ID Service Principal appId=$powerbiClientId tenantId=$powerbiTenantId"
```


#### 9. Acquire Power BI access token

```powershell
Write-Host "Getting Power BI access token..."
$body = @{
    client_id     = $powerbiClientId
    client_secret = $powerbiClientSecret
    scope         = "https://analysis.windows.net/powerbi/api/.default"
    grant_type    = "client_credentials"
}
$response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$powerbiTenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $body
$accessToken = $response.access_token
```


#### 10. Get the list of Power BI workspaces

```powershell
Write-Host "Getting the list of workspaces..."
$groupsUrl = "https://api.powerbi.com/v1.0/myorg/groups"
$groups = Invoke-RestMethod -Uri $groupsUrl -Method Get -Header $headers -ContentType "application/json"
```


#### 11. Find the specified Power BI workspace

```powershell
$workspaceId = $groups.value | Where-Object { $_.name -eq $Workspace } | Select-Object -First 1 -ExpandProperty id
if ($null -eq $workspaceId) {
    Write-Error "The workspace $Workspace has not been found."
    exit 1
}
```


#### 12. Get the list of datasets within the Power BI workspace

```powershell
Write-Host "Getting the list of datasets..."
$datasetsUrl = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/datasets"
$datasets = Invoke-RestMethod -Uri $datasetsUrl -Method Get -Header $headers -ContentType "application/json"
```


#### 12. Find the specified dataset in the Power BI workspace

```powershell
$datasetId = $datasets.value | Where-Object { $_.name -eq $Dataset } | Select-Object -First 1 -ExpandProperty id
if ($null -eq $datasetId) {
    Write-Error "The dataset $Dataset has not been found."
    exit 1
}
```


#### 13. Take over the Power BI dataset ownership (if no gateway)

> [!IMPORTANT]
> Please note that there is **no need** to take over the dataset ownership if a gateway (either VNET or On-premises gateway) is in use.
```powershell
if ($GatewayType -eq "NoGateway") {
    Write-Host "Taking over the dataset..."
    $takeoverUrl = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/Default.TakeOver"
    Invoke-RestMethod -Uri $takeoverUrl -Method Post -Header $headers -ContentType "application/json"
}
```


#### 14. Fetch Databricks datasource from the Power BI dataset

```powershell
Write-Host "Getting the list of datasources..."
$datasouresUrl = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/datasets/$datasetId/datasources"
$dataSources = Invoke-RestMethod -Uri $datasouresUrl -Method Get -Header $headers -ContentType "application/json"
# Find the datasource with the kind 'Databricks*'
$datasource = $datasources.value | Where-Object { $_.ConnectionDetails.kind -like 'Databricks*' } | Select-Object -First 1
if ($null -eq $datasource) {
    Write-Error "Databricks datasource has not been found."
    exit 1
}
```


#### 15. Construct a new Power BI credentials payload

> [!IMPORTANT]
> Please note that there is no need to encrypt credentials if no gateway or VNET gateway is in use, otherwise (On-premises gateway) credentials must be encrypted.

- Construct **non-encrypted** credentials payload
```powershell
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
```

- Construct **encrypted** credentials payload
```powershell 
    # Get the list of gateways
    Write-Host "Getting the list of gateways..."
    $gatewaysUrl = "https://api.powerbi.com/v1.0/myorg/gateways"
    $gateways = Invoke-RestMethod -Uri $gatewaysUrl -Method Get -Header $headers -ContentType "application/json"

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
```


#### 16. Update Power BI datasource credentials

```powershell
Write-Host "Updating the datasource credentials, gatewayId=$gatewayId , datasourceId=$datasourceId..." 
$datasourePatchUrl = "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources/$datasourceId"
Invoke-RestMethod -Method Patch -Uri $datasourePatchUrl -Body $body -Headers $headers -ContentType "application/json"
```
> [!IMPORTANT]
> Please note that it is assumed that the SQL Warehouse used by the Power BI dataset/datasource is the same as specified in the parameters of the script.If these are different SQL Warehouses, the script may fail while updating credentials.


#### 17. Optionally - trigger dataset refresh

```powershell
if ($RefreshDataset) {
    Write-Host "Triggering dataset $Dataset refresh..."
    $datasetRefreshUrl = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/refreshes"
    Invoke-RestMethod -Method Post -Uri $datasetRefreshUrl -Headers $headers -WarningAction Ignore
} else {
    Write-Host "Dataset refresh skipped."
}
```