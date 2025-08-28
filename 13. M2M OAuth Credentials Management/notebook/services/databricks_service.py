from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import (
    WarehouseAccessControlRequest,
    WarehousePermissionLevel,
)


class DatabricksService(object):

    def CreateClient(self):
        self.workspace_client = WorkspaceClient()
        self.max_secrets = 5

    def CheckServicePrincipal(self, service_principal_name):
        service_principal_id = None
        # Filter using SCIM filter syntax for display name
        service_principals = self.workspace_client.service_principals.list(filter=f"displayName eq {service_principal_name}")
        for sp in service_principals:
            service_principal_application_id = sp.application_id
            service_principal_id = sp.id

        if service_principal_id is None:
            print(f"Service Principal {service_principal_name} not found, creating a new one...")
            service_principals = self.workspace_client.service_principals.create(
                display_name=service_principal_name
            )
            service_principal_application_id = service_principals.application_id
            service_principal_id = service_principals.id

        print(f"Service Principal info: id={service_principal_id} appId={service_principal_application_id}")
        return (service_principal_application_id, service_principal_id)

    def CheckServicePrincipalSecret(self, service_principal_id):
        list_service_principal_secrets = (
            self.workspace_client.service_principal_secrets_proxy.list(
                service_principal_id=service_principal_id
            )
        )
        if len(list(list_service_principal_secrets)) >= self.max_secrets:
            raise ValueError(f"Service Principal {service_principal_id} has already {self.max_secrets} secrets. Creating more than {self.max_secrets} secrets is not supported. Please delete some of the secrets to continue.")
        print(f"Secrets count: {len(list(list_service_principal_secrets))}")

    def GenerateServicePrincipalSecret(self, service_principal_id, life_time):
        service_principal_secrets = (
            self.workspace_client.service_principal_secrets_proxy.create(
                service_principal_id=service_principal_id, lifetime=str(f"{life_time}s")
            )
        )
        print(f"A new secret has been generated for Service Principal with Id {service_principal_id} the creation time is {service_principal_secrets.create_time} and the expiry time is {service_principal_secrets.expire_time} and the status is currently {service_principal_secrets.status}")
        return service_principal_secrets.secret

    def GrantPermissionsOnWarehouse(self, service_principal_id, warehouse_id):
        response = self.workspace_client.warehouses.set_permissions(
            warehouse_id=warehouse_id,
            access_control_list=[
                WarehouseAccessControlRequest(
                    service_principal_name=service_principal_id,
                    permission_level=WarehousePermissionLevel.CAN_USE,
                )
            ],
        )
        print(f"Service Principal {service_principal_id} has been granted CAN_USE permission on SQL Warehouse {warehouse_id}")
