# Power BI Service connectivity to Databricks with Private Networking

## Private Networking Options for Databricks
When deploying Databricks with enhanced security, customers can choose from three main private networking configurations:
1. **Public Endpoint with an [IP Access List](https://learn.microsoft.com/en-us/azure/databricks/security/network/front-end/ip-access-list) for the Workspace** - this option exposes a public endpoint for the Databricks workspace but restricts access to specific IP ranges.
2. **[Databricks Private Link](https://learn.microsoft.com/en-us/azure/databricks/security/network/classic/private-link)** - front-end private link provides fully private connectivity, routing all traffic through private endpoints.
3. **Hybrid Deployment** - combines front-end private link with a public endpoint protected by a Workspace IP Access List which is typically used for SaaS service connections.


## Connecting Power BI to a Private Databricks Workspaces
While private networking enhances security, it can require additional connection configurations from SaaS services like Power BI. Power BI offers two primary methods for secure connections to data sources with private networking:
1. [On-premises data gateway](https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-onprem) - an application that gets installed on a Virtual Machine that has a direct networking connection to the data source. It allows Power BI to connect to data sources that don’t allow public connections.
2. [VNET data gateway](https://learn.microsoft.com/en-us/data-integration/vnet/overview) - a managed (virtual/serverless) data gateway that gets created and managed by the Power BI service.  Connections work by allowing Power BI to delegate into a VNet for secure connectivity to the data source.

While Power BI offers these two options, many customers prefer not to manage additional infrastructure or configurations required for these gateways. In such cases, Power BI can be allowed to access the private Databricks workspace through the [IP Access List](https://learn.microsoft.com/en-us/azure/databricks/security/network/front-end/ip-access-list) via the Public Endpoint. This is an option for scenarios #1 and #3 in the [Private Networking Options for Databricks](#private-networking-options-for-databricks) list above. If your Databricks workspace is deployed with no public endpoint, #2 in the [Private Networking Options for Databricks](#private-networking-options-for-databricks) list above, then configuring an IP Access List is not an option.


## Power BI connectivity via IP Access List
For more information on configuring Databricks IP Access Lists to secure Power BI connectivity to Databricks workspaces, see [Power BI connectivity via IP Access List](./Power%20BI%20Connectivity%20via%20IP%20ACLs.md) page.


## Power BI connectivity via Gateways
For more information on configuring Power BI gateways to secure Power BI connectivity to Databricks workspaces, see [Power BI connectivity via Gateways](./Power%20BI%20connectivity%20via%20Gateways.md) page.


## Conclusion
When using Power BI with Private Databricks Workspaces data practitioners need to configure network connectivity accordingly. The options include 
[On-premises data gateways](https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-onprem), [VNET data gateways](https://learn.microsoft.com/en-us/data-integration/vnet/overview), and [IP Access List](https://learn.microsoft.com/en-us/azure/databricks/security/network/front-end/ip-access-list).

By leveraging the sample code ([Databricks Notebook](https://github.com/yati1002/Power-BI-DatabricksSQL-QuickStart-Samples/blob/main/09.%20Private%20Connections/Power%20BI%20IPs%20for%20IP%20Access%20List.py), [Bash script](Configure%20Power%20BI%20IPs%20for%20Databricks%20IP%20ACLs.sh), [PowerShell script](Configure%20Power%20BI%20IPs%20for%20Databricks%20IP%20ACLs.ps1)) data practitioners can automate the creation and maintenance of Databricks Workspace IP Access Lists while keeping their workspaces secured.

For our findings and recommendations on choosing optimal configuration of a gateway, check [Power BI connectivity via Gateways](./Power%20BI%20connectivity%20via%20Gateways.md)