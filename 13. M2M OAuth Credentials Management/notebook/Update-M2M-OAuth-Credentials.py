# Databricks notebook source
# MAGIC %md
# MAGIC # Notebook environment tasks

# COMMAND ----------

# MAGIC %md
# MAGIC #### 1. Install the required libraries

# COMMAND ----------

# MAGIC %pip install --upgrade databricks-sdk
# MAGIC %restart_python

# COMMAND ----------

# MAGIC %md
# MAGIC #### 2. Set up the notebook to use parameters

# COMMAND ----------

dbutils.widgets.text("ServicePrincipal", "")
dbutils.widgets.text("WarehouseId", "")
dbutils.widgets.text("Workspace", "")
dbutils.widgets.text("Dataset", "")
dbutils.widgets.dropdown("GatewayType", "NoGateway", ["NoGateway", "Onpremises", "VNET"])
dbutils.widgets.text("Lifetime", "604800")
dbutils.widgets.dropdown("RefreshDataset", "true", ["true", "false"])
dbutils.widgets.text("SecretScope", "")
dbutils.widgets.text("ClientIdSecret", "")
dbutils.widgets.text("SecretSecret", "")
dbutils.widgets.text("TenantIdSecret", "")

# COMMAND ----------

# MAGIC %md
# MAGIC #### 3. Get the parameter values into variables to be used in the cells below

# COMMAND ----------

ServicePrincipal = dbutils.widgets.get("ServicePrincipal")
WarehouseId = dbutils.widgets.get("WarehouseId")
Workspace = dbutils.widgets.get("Workspace")
Dataset = dbutils.widgets.get("Dataset")
GatewayType = dbutils.widgets.get("GatewayType")
Lifetime = dbutils.widgets.get("Lifetime")
RefreshDataset = dbutils.widgets.get("RefreshDataset")
SecretScope = dbutils.widgets.get("SecretScope")
ClientIdSecret = dbutils.widgets.get("ClientIdSecret")
SecretSecret = dbutils.widgets.get("SecretSecret")
TenantIdSecret = dbutils.widgets.get("TenantIdSecret")

# COMMAND ----------

# MAGIC %md 
# MAGIC # Databricks Service Principal related tasks

# COMMAND ----------

# MAGIC %md
# MAGIC #### 4. Check if service principal exists, if not create one

# COMMAND ----------

from services.databricks_service import DatabricksService
dbx_svc = DatabricksService()
dbx_svc.CreateClient()

# COMMAND ----------

ServicePrincipalApplicationId, ServicePrincipaId = dbx_svc.CheckServicePrincipal(ServicePrincipal)

# COMMAND ----------

# MAGIC %md
# MAGIC #### 5. Check if the service principal has the maximum allowed secrets

# COMMAND ----------

dbx_svc.CheckServicePrincipalSecret(ServicePrincipaId)

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC #### 6. Create a new secret for the Service Principal

# COMMAND ----------

ServicePrincipalSecret = dbx_svc.GenerateServicePrincipalSecret(ServicePrincipaId,Lifetime)

# COMMAND ----------

# MAGIC %md
# MAGIC #### 7. Grant Service Principal CAN USE permission on the SQL Warehouse

# COMMAND ----------

dbx_svc.GrantPermissionsOnWarehouse(ServicePrincipalApplicationId, WarehouseId)

# COMMAND ----------

# MAGIC %md
# MAGIC # Power BI related tasks

# COMMAND ----------

# MAGIC %md
# MAGIC #### 8. Retrieve Entra ID Service Principal credentials from Databricks secrets

# COMMAND ----------

PowerBIClientId = dbutils.secrets.get(SecretScope, ClientIdSecret)
PowerBIClientSecret = dbutils.secrets.get(SecretScope, SecretSecret)
PowerBITenantId = dbutils.secrets.get(SecretScope, TenantIdSecret)

# COMMAND ----------

# MAGIC %md
# MAGIC #### 9. Acquire Power BI access token

# COMMAND ----------

from services.powerbi_service import PowerbiService

pbi_svc = PowerbiService()
pbi_svc.CreateCredential(
    tenant_id=PowerBITenantId,
    client_id=PowerBIClientId,
    client_secret=PowerBIClientSecret,
)

# COMMAND ----------

# MAGIC %md
# MAGIC #### 10. Get the Workspace Id by the Workspace name

# COMMAND ----------

WorkspaceId = pbi_svc.GetWorkspaceId(Workspace)

# COMMAND ----------

# MAGIC %md
# MAGIC #### 11. Get the Dataset id by the Dataset name

# COMMAND ----------

DatasetId = pbi_svc.GetDatasetId(WorkspaceId,Dataset)

# COMMAND ----------

# MAGIC %md
# MAGIC #### 12. Take over the Power BI dataset ownership (if no gateway)

# COMMAND ----------

if GatewayType == "NoGateway":
    pbi_svc.TakOverDataset(WorkspaceId, DatasetId)

# COMMAND ----------

# MAGIC %md 
# MAGIC #### 13. Fetch Databricks datasource from the Power BI dataset

# COMMAND ----------

GatewayId, DataSourceId = pbi_svc.GetDatasetDatasource(WorkspaceId, DatasetId)

# COMMAND ----------

# MAGIC %md
# MAGIC #### 14. Construct a new Power BI credentials payload

# COMMAND ----------

from services.encrypt_credentials_service import EncryptCredentialsService

if GatewayType == "Onpremises":
    public_key = pbi_svc.GetGatewayPublicKey(GatewayId)
    enc = EncryptCredentialsService(public_key)
    EncryptionAlgorithm = "RSA-OAEP"
    Credentials = enc.EncodeCredentials(
        "{'credentialData':[{'name':'username','value':'"
        + ServicePrincipalApplicationId
        + "'},{'name':'password','value':'"
        + ServicePrincipalSecret
        + "'}]}"
    )
else:
    EncryptionAlgorithm = "None"
    Credentials = f'{{"credentialData":[{{"name":"username", "value": "{ServicePrincipalApplicationId}"}},{{"name":"password", "value": "{ServicePrincipalSecret}"}}]}}'

# COMMAND ----------

# MAGIC %md
# MAGIC #### 15. Update Power BI datasource credentials

# COMMAND ----------

pbi_svc.UpdateDatasetDatasource(GatewayId, DataSourceId, Credentials, EncryptionAlgorithm)

# COMMAND ----------

# MAGIC %md
# MAGIC #### 16. Optionally - trigger dataset refresh

# COMMAND ----------

if RefreshDataset == "true":
    pbi_svc.RefreshDataset(WorkspaceId, DatasetId)
