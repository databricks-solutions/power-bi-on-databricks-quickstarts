
# Power BI Connectivity via IP Access List

## Overview
To enable the Power BI Service connectivity to a private Databricks workspace using IP Access Lists follow these steps.

1. Download the latest [Azure IP Ranges and Service Tags](https://www.microsoft.com/en-us/download/details.aspx?id=56519) file from the Microsoft Download Center. This file is updated weekly and contains IP ranges for various Azure services, including Power BI.
2. Add Power BI IP ranges to Databricks Workspace IP ACLs by extracting the Power BI IP ranges from the downloaded file and adding them to the Databricks IP ACLs using the [CLI](https://learn.microsoft.com/en-us/azure/databricks/security/network/front-end/ip-access-list-workspace), [API](https://docs.databricks.com/api/workspace/ipaccesslists), or [SDK](https://databricks-sdk-py.readthedocs.io/en/latest/workspace/settings/ip_access_lists.html). 
3. Update regularly. Since Power BI public IPs are subject to change, it's crucial to update the Workspace IP ACLs on a regular basis. 


## Sample Implementations
To automate creating and updating Databricks Workspace IP Access Lists we offer sample implementations using [Databricks Notebooks](#databricks-notebooks) and [Standalone scripts](#standalone-scripts) (Bash and PowerShell) which offer similar capabilities.

### Databricks Notebooks
IP Access List maintenance can be automated using a Databricks Job and a notebook that periodically downloads the latest IP ranges and updates the Workspace IP Access List. The Job needs to be run by a Workspace Admin in order to set the configurations. You can run the Databricks Job as a Service Principal to make the updates. If you use the Databricks SDK from within a notebook in the Databricks Workspace, [authentication](https://databricks-sdk-py.readthedocs.io/en/latest/authentication.html#notebook-native-authentication) is handled for you.

The sample code includes 2 notebooks:
- [Turn on Workspace IP Access List.py](Turn%20on%20Workspace%20IP%20Access%20List.py) which is more of a one-time operation 
- [Power BI IPs for IP Access List.py](./Power%20BI%20IPs%20for%20IP%20Access%20List.py) which refreshes IP Access List by adding Power BI IP ranges.

### Standalone scripts

- [Configure Power BI IPs for Databricks IP ACLs.ps1](Configure%20Power%20BI%20IPs%20for%20Databricks%20IP%20ACLs.ps1)
- [Configure Power BI IPs for Databricks IP ACLs.sh](Configure%20Power%20BI%20IPs%20for%20Databricks%20IP%20ACLs.sh)

#### Prerequisites
- Databricks CLI [installed](https://learn.microsoft.com/en-us/azure/databricks/dev-tools/cli/install) and [configured](https://learn.microsoft.com/en-us/azure/databricks/dev-tools/cli/authentication)
- Databricks Workspace admin rights

#### Executing the script

##### PowerShell

Adding IP ranges for all Power BI regions:
```powershell  
& './Configure Power BI IPs for Databricks IP ACLs.ps1' 
```

Adding IP ranges for a specific Power BI region:
```powershell  
& './Configure Power BI IPs for Databricks IP ACLs.ps1' -Location "eastus"  
```

##### Bash

Adding IP ranges for all Power BI regions:
```bash  
'./Configure Power BI IPs for Databricks IP ACLs.sh'
```
Adding IP ranges for a specific Power BI region:
```bash  
'./Configure Power BI IPs for Databricks IP ACLs.sh' eastus
```

Valid Locations: `westeurope`, `eastus2`, etc.
*(Full list: `az account list-locations -o table`)*


#### How it works
1. Downloads the latest [Azure IP Ranges and Service Tags](https://www.microsoft.com/en-us/download/details.aspx?id=56519) file from the Microsoft Download Center.
2. Parses the file and filters Power BI IP ranges only.
3. Filters IPv4 addresses.
4. Creates or updates Databricks workspace IP Access List with a label **Power-BI-IP-for-Databricks-IP-ACLs-Automation**.

***Please note that the script only creates IP Access List but it neither enables nor disables it.***

In order to enable IP Access List use the following Databricks CLI command:
```
databricks ip-access-lists update 'Power-BI-IP-for-Databricks-IP-ACLs-Automation' --json '{ "enabled": true }'
```
In order to disable IP Access List use the following Databricks CLI command:
```
databricks ip-access-lists update 'Power-BI-IP-for-Databricks-IP-ACLs-Automation' --json '{ "enabled": false }'
```

#### Common issues
| Problem | Solution |
| :-- | :-- |
| *Error: Your current IP \*.\*.\*.\* will not be allowed to access the workspace under current configuration* | Make sure that before running the script you create IP Access List allowing access from your current IP address |
| *Service tags unavailable* | Verify that the region provided as parameter supports Power BI |
| *403 Forbidden* | Check Databricks admin rights |
| Script errors | Run with `-Verbose` (PowerShell) or `bash -x` (Bash) |
| *Permission denied* on scripts | `chmod +x *.sh && dos2unix *.sh` |
| *bash: bad interpreter* | Run `dos2unix` on Windows-created scripts |


