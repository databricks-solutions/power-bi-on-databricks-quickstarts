<#
.SYNOPSIS
    Configure Power BI IP addresses for Databricks IP Access Control Lists (ACLs)
.DESCRIPTION
    This script retrieves the latest Power BI IP addresses from Azure's public IP ranges and configures them in Databricks IP Access Control Lists (ACLs). 
    It supports specifying an Azure region to filter the Power BI IPs accordingly. If no region is specified, it defaults to empty (global).
.PARAMETER Location
    The Azure region for which to configure Power BI IPs. Default is empty (global). Examples: "eastus", "westeurope", etc.
.INPUTS
    None
.OUTPUTS
    None
.EXAMPLE
    # PS> & './Configure Power BI IPs for Databricks IP ACLs.ps1' eastus
    #     Retrieves IP addresses for Power BI in the East US region and configures the Databricks IP ACL accordingly.
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrWhiteSpace()]
    [string]$Location
)

# Check Databricks CLI installation
if (-not (Get-Command databricks -ErrorAction SilentlyContinue)) {
  Write-Error "Databricks CLI is not installed. Please install it and try again. See more details here - https://docs.databricks.com/aws/en/dev-tools/cli/install."
  exit 1
}

# Check if the Location parameter was explicitly provided
if ($PSBoundParameters.ContainsKey('Location')) {
    Write-Host "Using provided location: $Location" -ForegroundColor Green
    $Label = "Power-BI-IP-for-Databricks-IP-ACLs-Automation-$Location"
}
else {
    Write-Host "Using default location: $Location" -ForegroundColor Yellow
    $Label = "Power-BI-IP-for-Databricks-IP-ACLs-Automation"
}

$ErrorActionPreference = "Stop"

function Get-AzureIpRanges {
  $downloadPage = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519"
  $tagIdentifier = "ServiceTags_Public"
  $networkData = @()
  try {
      # Step 1: Download the main page to find the current JSON link
      $pageResult = Invoke-WebRequest -Uri $downloadPage -UseBasicParsing
      
      # Step 2: Extract download link that matches our pattern
      $jsonDownloadLink = $pageResult.Links | 
          Where-Object { $_.href -match $tagIdentifier -and $_.href -match '\.json$' } | 
          Select-Object -First 1 -ExpandProperty href
      
      if ($jsonDownloadLink) {
          Write-Verbose "Found JSON download URL: $jsonDownloadLink"
          
          $jsonContent=Invoke-WebRequest -Uri $jsonDownloadLink | ConvertFrom-Json
         
          # Step 3: Extract service tags from the correct JSON structure
          if ($jsonContent -and $jsonContent.values) {
              $networkData = $jsonContent.values
              Write-Verbose "Successfully extracted $(($networkData).Count) service tags"
          }
          else {
              Write-Warning "JSON structure doesn't contain the expected 'values' property"
              Write-Verbose "Available properties: $(($jsonContent | Get-Member -MemberType Properties).Name -join ', ')"
          }
      }
      else {
          Write-Warning "Couldn't find download link matching pattern '$tagIdentifier'"
      }
  }
  catch {
      Write-Error "Failed to retrieve Azure IP ranges: $_"
  }
  
  return $networkData
}


Write-Host "Starting Power BI IP addresses for Databricks IP ACLs automation..."


# Download and parse Azure IP ranges
Write-Host "Downloading Azure public IP ranges..."
$azureIpRanges = Get-AzureIpRanges

# Filter for Power BI service tags 
Write-Host "Filtering Power BI IP ranges using case-insensitive match..."
$powerBIRanges = $azureIpRanges | Where-Object {
    ($_.name -ilike 'powerbi*') -and ($_.properties.region -ieq $Location)
}

if (-not $powerBIRanges) {
    Write-Error "No PowerBI service tag found at all."
    exit 1
}

# Extract IPv4 addresses
$ipv4Addresses = $powerBIRanges.Properties.AddressPrefixes | Where-Object { $_ -notmatch ':' } | Sort-Object -Unique

if (-not $ipv4Addresses) {
    Write-Error "No Power BI IPv4 addresses found for region $Location"
    exit 1
}


# Format for JSON
$formattedIPs = $ipv4Addresses | ForEach-Object { "`"$_`"" }
$ipAddressesJson = $formattedIPs -join ",`n    "

# List existing IP access lists
Write-Host "Listing existing IP access lists..."
$listCommand = "databricks ip-access-lists list --output json"
$listOutput = Invoke-Expression $listCommand | ConvertFrom-Json

# Find the list with the specified label
Write-Host "Searching for existing list with label: $Label"
$existingList = $listOutput | Where-Object { $_.label -eq $Label }

if ($existingList) {
    # If the list exists, update it
    Write-Host "Existing list found. Preparing update command..."
    $updateCommand = @"
databricks ip-access-lists update $($existingList.list_id) --json '{
  "label": "$Label",
  "list_type": "ALLOW",
  "ip_addresses": [
    $ipAddressesJson
  ]
}'
"@
    Write-Host "Updating existing IP access list with label '$Label':"
} else {
    # If the list doesn't exist, create a new one
    Write-Host "No existing list found. Preparing create command..."
    $createCommand = @"
databricks ip-access-lists create --json '{
  "label": "$Label",
  "list_type": "ALLOW",
  "ip_addresses": [
    $ipAddressesJson
  ]
}'
"@
    Write-Host "Creating new IP access list with label '$Label':"
}

# Uncomment the following lines to execute the command
Write-Host "Executing command..."
if ($existingList) {
     Invoke-Expression $updateCommand
} else {
     Invoke-Expression $createCommand
}

Write-Host "Script execution completed."
