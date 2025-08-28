import json
import requests


class PowerbiService(object):

    def CreateCredential(self, tenant_id, client_id, client_secret):
        self.base_url = "https://api.powerbi.com/v1.0/myorg/"
        self.scope = "https://analysis.windows.net/powerbi/api/.default"
        self.client_id = client_id
        self.tenant_id = tenant_id  #!!
        self.client_secret = client_secret #!!

    def GetAccessToken(self):
        token_url = f"https://login.microsoftonline.com/{self.tenant_id}/oauth2/v2.0/token"
        headers = {"Content-Type": "application/x-www-form-urlencoded"}
        requestBody = {
                "client_id": f"{self.client_id}",
                "client_secret": f"{self.client_secret}",
                "scope": f"{self.scope}",
                "grant_type": "client_credentials"
            }
        response = requests.post(token_url, headers=headers, data=requestBody)
        accessToken = response.json().get("access_token")
        return accessToken

    def GetRequestHeader(self):
        return {
            "Content-Type": "application/json",
            "Authorization": "Bearer " + self.GetAccessToken(),
        }

    def GetGatewayPublicKey(self, GatewayId):
        headers = self.GetRequestHeader()
        response = requests.get(f"{self.base_url}gateways/{GatewayId}", headers=headers)
        temp = json.loads(response.text)
        return temp["publicKey"]

    def GetDatasetId(self, WorkspaceId, dataset_name):
        headers = self.GetRequestHeader()
        response = requests.get(f"{self.base_url}groups/{WorkspaceId}/datasets", headers=headers)
        temp = json.loads(response.text)
        for i in temp["value"]:
            if i["name"] == dataset_name:
                DatasetId = i["id"]
        return DatasetId

    def GetWorkspaceId(self, workspace_name):
        headers = self.GetRequestHeader()
        response = requests.get(f"{self.base_url}groups?$filter=name%20eq%20'{workspace_name}'", headers=headers)
        if response.status_code != 200:
            raise ValueError(f"Error retrieving the workspace id, the status code is {response.status_code} and the error message is {response.text}")
        elif len(json.loads(response.text)["value"]) == 0:
            raise ValueError(f"Workspace {workspace_name} does not exist or the service principal {self.client_id} does not have access to it")
        else:
            temp = json.loads(response.text)
            return temp["value"][0]["id"]

    def GetDatasetDatasource(self, WorkspaceId, DatasetId):
        headers = self.GetRequestHeader()
        response = requests.get(f"{self.base_url}groups/{WorkspaceId}/datasets/{DatasetId}/datasources", headers=headers)
        temp = json.loads(response.text)
        for i in temp["value"]:
            if i["connectionDetails"]["kind"] == "Databricks":
                GatewayId = i["gatewayId"]
                DataSourceId = i["datasourceId"]
        return (GatewayId, DataSourceId)

    def TakOverDataset(self, WorkspaceId, DatasetId):
        headers = self.GetRequestHeader()
        response = requests.post(f"{self.base_url}groups/{WorkspaceId}/datasets/{DatasetId}/Default.TakeOver", headers=headers)
        if response.status_code == 200:
            print(f"The dataset ownership is now assigned to the Service Principal {self.client_id}")
        else:
            raise ValueError(f"Service Principal {self.client_id} does not have permissions to take over the dataset")

    def RefreshDataset(self, WorkspaceId, DatasetId):
        headers = self.GetRequestHeader()
        requestBodyJson = {"notifyOption": "NoNotification"}
        response = requests.post(f"{self.base_url}groups/{WorkspaceId}/datasets/{DatasetId}/refreshes", json=requestBodyJson, headers=headers)
        if response.status_code != 202:
            raise ValueError(f"Error refreshing the dataset, the status code is {response.status_code} and the error message is {response.text}")
        else:
            print(f"Dataset {DatasetId} refresh request submitted")

    def UpdateDatasetDatasource(
        self, GatewayId, DataSourceId, Credentials, EncryptionAlgorithm
    ):
        print(f"Updating the datasource credentials, gatewayId={GatewayId} , datasourceId={DataSourceId}...")
        headers = self.GetRequestHeader()
        requestBodyJson = {
            "credentialDetails": {
                "credentialType": "Basic",
                "credentials": Credentials,
                "encryptedConnection": "Encrypted",
                "encryptionAlgorithm": EncryptionAlgorithm,
                "privacyLevel": "Organizational",
                "useEndUserOAuth2Credentials": "False",
            }
        }
        response = requests.patch(f"{self.base_url}gateways/{GatewayId}/datasources/{DataSourceId}", json=requestBodyJson, headers=headers)
        if response.status_code != 200:
            raise ValueError(f"Error updating the datasource, the status code is {response.status_code} and the error message is {response.text}")
        else:
            print("Updated the datasource credentials")
