# M2M OAuth Credentials Management - Bash


## Prerequisites

Before you begin, ensure you have the following:

- [Databricks account](https://databricks.com/), access to a Databricks workspace, and Databricks SQL Warehouse
    - [Permissions](https://docs.databricks.com/aws/en/admin/users-groups/service-principals#who-can-manage-and-use-service-principals) to create and manage service principals, either **Account admins** or **Workspace admins**. 
- [Databricks CLI](https://docs.databricks.com/aws/en/dev-tools/cli/), version 0.264 or above
    - [Databricks CLI](https://docs.databricks.com/aws/en/dev-tools/cli/) must be configured for the target Databricks Workspace and authentication method using ``databricks configure`` command.
- [Microsoft Entra ID Service Principal](https://learn.microsoft.com/en-us/entra/identity-platform/app-objects-and-service-principals) which has permissions to access target Power BI workspace, dataset, gateway
    - `ClientID`, `Secret`, and `TenantID` must be stored as [Databricks secrets](https://docs.databricks.com/aws/en/security/secrets/)
    - Entra ID Service Principal must have permisions to change settings of the dataset and the gateway (if gateway is in use)

> [!NOTE]
> This code utilizes the [Power BI REST API](https://learn.microsoft.com/en-us/rest/api/power-bi/) as described in the official Power BI REST API documentation and does not require installation of additional packages or libraries.


## Parameters

| **Parameter**         | **Purpose**                                                                                     |
| --------------------- | ----------------------------------------------------------------------------------------------- |
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
```bash
$ Update-M2M-OAuth-Credentials.sh 
    --ServicePrincipal <String>
    --WarehouseId <String>
    --Workspace <String>
    --Dataset <String>
    --Lifetime <Int32> 
    --GatewayType <String>
    --Profile <String>
    --SecretScope <String>
    --ClientIdSecret <String>
    --SecretSecret <String>
    --TenantIdSecret <String>
    --RefreshDataset
```


## Example
```bash
$ Update-M2M-OAuth-Credentials.sh `
    --ServicePrincipal "MyServicePrincipal" `
    --WarehouseId "a5ad4687dadae274" `
    --Workspace "SPN-rotation-test" `
    --Dataset "tpch-no-gateway" `
    --Lifetime 600 `
    --GatewayType "NoGateway" `
    --Profile "DEFAULT" `
    --SecretScope "powerbi_credentials" `
    --ClientIdSecret "powerbi_client_id" `
    --SecretSecret "powerbi_client_secret" `
    --TenantIdSecret "powerbi_tenant_id" `
    --RefreshDataset
```

```output
[INFO] Databricks CLI version is 0.264.2 (>= 0.264.2). Proceeding...
[INFO] Checking if Service Principal MyServicePrincipal exists...
[INFO] Service Principal id=147899502163423 appId=70408dec-2146-475a-a16e-2ccde4bfbc47
[INFO] Getting the list of secrets...
[INFO] Secrets count: 1
[INFO] Creating Secret...
[INFO] Granting Service Principal MyServicePrincipal CAN USE permissionon SQL Warehouse a5ad4687dadae274...
[INFO] Getting Entra ID Service Principal...
[INFO] Entra ID Service Principal info: appId=034be9fb-f1b5-4dd4-b666-25e8166a51c4 tenantId=9f37a392-f0ae-4280-9796-f1864a10effc
[INFO] Acquiring Power BI access token...
[INFO] Getting the list of workspaces...
[INFO] Getting the list of datasets...
[INFO] Taking over the dataset...
[INFO] Getting the list of datasources...
[INFO] Updating the datasource credentials, gatewayId=c8f401ed-83dd-4bba-be45-4635d32099b1, datasourceId=0390f438-9801-485d-95f3-2c5fccf4369e...
[INFO] Triggering dataset tpch-no-gateway refresh...
[INFO] Execution completed
```


## Script walkthrough

> [!IMPORTANT]
> Microsoft does not officially support VNET managed gateways via the [Power BI REST API](https://learn.microsoft.com/en-us/rest/api/power-bi/), and the functionality described here is not guaranteed. Future changes by Microsoft to the [Power BI REST API](https://learn.microsoft.com/en-us/rest/api/power-bi/) or VNET managed gateway behavior may impact compatibility or performance of this solution. Use at your own risk.


#### 1. Validate Databricks CLI installation

```bash
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Error: required command '$1' not found" >&2; exit 1; }; }
...
need_cmd databricks
```


#### 2. Validate Databricks CLI verion

```bash
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
```


#### 3. Check if the Service Principal exists

```bash
log_info "Checking if Service Principal ${SERVICE_PRINCIPAL_NAME} exists..."
spn_json="$(databricks service-principals list --filter "displayName eq ${SERVICE_PRINCIPAL_NAME}" --output json --profile "${PROFILE}" || true)"
spn_id="$(printf '%s' "${spn_json}" | jq -r '.[0].id // empty')"
app_id="$(printf '%s' "${spn_json}" | jq -r '.[0].applicationId // empty')"
```


#### 4. Create the Service Principal if it does not exist

```bash
if [[ -z "${spn_id}" ]]; then
  log_info "Creating Service Principal ${SERVICE_PRINCIPAL_NAME}..."
  spn_create_json="$(databricks service-principals create --display-name "${SERVICE_PRINCIPAL_NAME}" --output json --profile "${PROFILE}")"
  spn_id="$(printf '%s' "${spn_create_json}" | jq -r '.id')"
  app_id="$(printf '%s' "${spn_create_json}" | jq -r '.applicationId')"
fi
log_info "Service Principal info: id=${spn_id} appId=${app_id}"
```


#### 5. Validate the Service Principal secrets limit (max 5 secrets allowed)

```bash
log_info "Getting the list of secrets..."
secrets_json="$(databricks service-principal-secrets-proxy list "${spn_id}" --output json --profile "${PROFILE}" || echo '[]')"
secrets_count="$(printf '%s' "${secrets_json}" | jq 'length')"
log_info "Secrets count: ${secrets_count}"
if [[ "${secrets_count}" -eq 5 ]]; then
  log_error "Service Principal ${SERVICE_PRINCIPAL_NAME} has already 5 secrets. Creating more than 5 secrets is not supported. Please delete some of the secrets to continue."
  exit 1
fi
```


#### 6. Create a new secret for the Service Principal

```bash
log_info "Creating Secret..."
secret_json="$(databricks service-principal-secrets-proxy create "${spn_id}" --lifetime "${LIFETIME}s" --output json --profile "${PROFILE}")"
secret_value="$(printf '%s' "${secret_json}" | jq -r '.secret')"
```


#### 7. Grant CAN USE permission for the Service Principal on the SQL Warehouse

```bash
log_info "Setting permissions for Service Principal ${SERVICE_PRINCIPAL_NAME} on SQL Warehouse "${WAREHOUSE_ID}"..."
perm_json="$(jq -n --arg sp "${app_id}" '{access_control_list:[{service_principal_name:$sp, permission_level:"CAN_USE"}]}')"
databricks warehouses set-permissions "${WAREHOUSE_ID}" --json "${perm_json}" --profile "${PROFILE}" >/dev/null

```


#### 8. Retrieve Power BI credentials from Databricks secrets

```bash
log_info "Getting Entra ID Service Principal..."
client_id="$(databricks secrets get-secret "${SECRET_SCOPE}" "${CLIENT_ID_SECRET}" --output json --profile "${PROFILE}" | jq -r .value | base64 --decode)"
secret="$(databricks secrets get-secret "${SECRET_SCOPE}" "${SECRET_SECRET}" --output json --profile "${PROFILE}" | jq -r .value | base64 --decode)"
tenant_id="$(databricks secrets get-secret "${SECRET_SCOPE}" "${TENANT_ID_SECRET}" --output json --profile "${PROFILE}" | jq -r .value | base64 --decode)"
log_info "Entra ID Service Principal appId=${client_id} tenantId=${tenant_id}"
```


#### 9. Acquire Power BI access token

```bash
log_info "Acquiring Power BI access token..."
token_url="https://login.microsoftonline.com/$tenant_id/oauth2/v2.0/token"
scope="https://analysis.windows.net/powerbi/api/.default"
access_token="$(curl -s -X POST $token_url -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=client_credentials&client_id=$client_id&client_secret=$secret&scope=$scope" | jq -r '.access_token')"
```


#### 10. Get the list of Power BI workspaces

```bash
log_info "Getting the list of workspaces..."
groups_json="$(curl -sS -H "${auth_header[@]}" -H "${content_type[@]}" "https://api.powerbi.com/v1.0/myorg/groups")"
```


#### 11. Find the specified Power BI workspace

```bash
workspace_id="$(printf '%s' "${groups_json}" | jq -r --arg n "${WORKSPACE_NAME}" '.value[] | select(.name==$n) | .id' | head -n1)"
if [[ -z "${workspace_id}" ]]; then
  log_error "The workspace ${WORKSPACE_NAME} has not been found."
  exit 1
fi
```


#### 12. Get the list of datasets within the Power BI workspace

```bash
log_info "Getting the list of datasets..."
datasets_json="$(curl -sS -H "${auth_header[@]}" -H "${content_type[@]}" "https://api.powerbi.com/v1.0/myorg/groups/${workspace_id}/datasets")"
```


#### 12. Find the specified dataset in the Power BI workspace

```bash
dataset_id="$(printf '%s' "${datasets_json}" | jq -r --arg n "${DATASET_NAME}" '.value[] | select(.name==$n) | .id' | head -n1)"
if [[ -z "${dataset_id}" ]]; then
  log_error "The dataset ${DATASET_NAME} has not been found."
  exit 1
fi
```


#### 13. Take over the Power BI dataset ownership (if no gateway)

> [!IMPORTANT]
> Please note that there is **no need** to take over the dataset ownership if a gateway (either VNET or On-premises gateway) is in use.
```bash
if [[ "$GATEWAY_TYPE" == "NoGateway" ]]; then
  log_info "Taking over the dataset..."
  curl -sS -X POST -H "${auth_header[@]}" -H "${content_type[@]}" "https://api.powerbi.com/v1.0/myorg/groups/${workspace_id}/datasets/${dataset_id}/Default.TakeOver" -d '{}' >/dev/null
fi
```


#### 14. Fetch Databricks datasource from the Power BI dataset

```bash
log_info "Getting the list of datasources..."
datasources_json="$(curl -sS -H "${auth_header[@]}" -H "${content_type[@]}" "https://api.powerbi.com/v1.0/myorg/groups/${workspace_id}/datasets/${dataset_id}/datasources")"
# Find the datasource with the kind 'Databricks*'
datasource_line="$(printf '%s' "${datasources_json}" | jq -r '.value[] | select(((.ConnectionDetails.kind // .connectionDetails.kind // "") | test("^Databricks"))) | [.datasourceId, .gatewayId] | @tsv' | head -n1)"
if [[ -z "${datasource_line}" ]]; then
  log_error "Databricks datasource has not been found."
  exit 1
fi
```


#### 15. Construct a new Power BI credentials payload

> [!IMPORTANT]
> Please note that there is no need to encrypt credentials if no gateway or VNET gateway is in use, otherwise (On-premises gateway) credentials must be encrypted.

- Construct **non-encrypted** credentials payload
```bash
# No gateway or managed VNET gateway - use non-encrypted credentials
cred_str="$(jq -cn --arg u "${username}" --arg p "${password}" '{credentialData:[{name:"username",value:$u},{name:"password",value:$p}]}' | jq -c .)"
body_json="$(jq -n --arg cs "${cred_str}" '{credentialDetails:{credentialType:"Basic", credentials:$cs, encryptedConnection:"Encrypted", encryptionAlgorithm:"None", privacyLevel:"Organizational"}}')"
```

- Construct **encrypted** credentials payload
```bash 
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

# Instantiate the credentials encryptor service (bash version)
serialized_credentials="{'credentialData':[{'name':'username', 'value':'${username}'},{'name':'password', 'value':'${password}'}]}"
encrypted_credentials="$("${SCRIPT_DIR}/encrypt_credential_service.sh" "${gateway_exponent_b64}" "${gateway_modulus_b64}" "${serialized_credentials}")"

body_json="$(jq -n --arg enc "${encrypted_credentials}" '{credentialDetails:{credentialType:"Basic", credentials:$enc, encryptedConnection:"Encrypted", encryptionAlgorithm:"RSA-OAEP", privacyLevel:"Private"}}')"
```


#### 16. Update Power BI datasource credentials

```bash
log_info "Updating the datasource credentials, gatewayId=${gateway_id}, datasourceId=${datasource_id}..."
curl -sS -X PATCH -H "${auth_header[@]}" -H "${content_type[@]}" -d "${body_json}" "https://api.powerbi.com/v1.0/myorg/gateways/${gateway_id}/datasources/${datasource_id}" >/dev/null
```

> [!IMPORTANT]
> Please note that it is assumed that the SQL Warehouse used by the Power BI dataset/datasource is the same as specified in the parameters of the script.If these are different SQL Warehouses, the script may fail while updating credentials.


#### 17. Optionally - trigger dataset refresh

```bash
log_info "Triggering dataset ${DATASET_NAME} refresh..."
curl -sS -X POST -H "${auth_header[@]}" -H "${content_type[@]}" -d '{}' "https://api.powerbi.com/v1.0/myorg/groups/${workspace_id}/datasets/${dataset_id}/refreshes" >/dev/null || true
```