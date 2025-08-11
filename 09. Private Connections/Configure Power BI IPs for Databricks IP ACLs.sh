#!/bin/bash

# Set variables with default value
LOCATION=${1:-"global"}

# Check if Databricks CLI is installed
if ! command -v databricks &> /dev/null; then
    echo "Databricks CLI is not installed. Please install it and try again. See more details here - https://docs.databricks.com/aws/en/dev-tools/cli/install."
    exit 1
fi
# Check if Location parameter was provided or using default
if [ $# -ge 1 ]; then
    echo "Using provided location: $LOCATION"
    PBserviceTag="PowerBI.$LOCATION"
    LABEL="Power-BI-IP-for-Databricks-IP-ACLs-Automation-$LOCATION"
else
    echo "Using default location: $LOCATION"
    PBserviceTag="PowerBI"
    LABEL="Power-BI-IP-for-Databricks-IP-ACLs-Automation"
fi

# Function to get Azure public IP ranges
get_azure_public_ip_ranges() {
    # URL for the download page
    uri="https://www.microsoft.com/en-us/download/details.aspx?id=56519"
    
    # Fetch the page content
    response=$(curl -s "$uri")
    links=$(echo "$response" | grep -oE 'href="[^"]*ServiceTags_Public[^"]*"')
    if [ -n "$links" ]; then
        jsonUri=$(echo "$links" | cut -d'"' -f2)
        # Use jq to keep the array structure intact
        ipRanges=$(curl -s "$jsonUri" | jq '.values')
        echo "$ipRanges"
    fi
}

# Function to filter Power BI IP ranges for the specified region
filter_power_bi_ip_ranges() {
    serviceTagRegion=${LOCATION// /}
    powerbiServiceTag=$PBserviceTag
    ipRanges=$(get_azure_public_ip_ranges)
    
    # First try to find region-specific PowerBI tag
    powerBIRanges=$(echo "$ipRanges" | jq -c ".[] | select(.name == \"$powerbiServiceTag\")")
    
    # If no region-specific tag found, try global PowerBI tag
    if [ -z "$powerBIRanges" ] || [ "$powerBIRanges" == "" ]; then
        powerBIRanges=$(echo "$ipRanges" | jq -c ".[] | select(.name == \"PowerBI\")")
    fi
    
    echo "$powerBIRanges"
}

# Function to extract IPv4 addresses
extract_ipv4_addresses() {
    ipRanges=$(filter_power_bi_ip_ranges)
    
    if [ -z "$ipRanges" ] || [ "$ipRanges" == "" ]; then
        echo "No PowerBI IP ranges found for region: $LOCATION"
        return 1
    fi
    # Extract IPv4 addresses from the properties.addressPrefixes array
    ipv4Addresses=$(echo "$ipRanges" | jq -r '.properties.addressPrefixes[] | select(contains(".") and (contains(":") | not))')
    echo "$ipv4Addresses"
}

# Main script
echo "Starting Power BI IP addresses for Databricks IP ACLs automation..."

# Download and parse Azure IP ranges
echo "Downloading Azure public IP ranges..."
azureRanges=$(get_azure_public_ip_ranges)
# Filter Power BI IP ranges for specified region
echo "Filtering for Power BI service tag..."
powerBIRanges=$(filter_power_bi_ip_ranges)
# Extract and filter IPv4 addresses
echo "Extracting IPv4 addresses..."
ipv4Addresses=$(extract_ipv4_addresses)

if [ -z "$ipv4Addresses" ]; then
    echo "No Power BI IPv4 addresses found for region $LOCATION"
    exit 1
fi

# Format IP addresses for JSON - this is the fixed part
ipAddressesJson=$(echo "$ipv4Addresses" | awk '{print "\""$0"\""}' | paste -sd "," -)

# List existing IP access lists
echo "Listing existing IP access lists..."
listCommand="databricks ip-access-lists list --output json"
listOutput=$(eval "$listCommand")

# Find the list with the specified label
echo "Searching for existing list with label: $LABEL"
existingList=$(echo "$listOutput" | jq ".[] | select(.label == \"$LABEL\")")

if [ -n "$existingList" ]; then
    # If the list exists, update it
    echo "Existing list found. Preparing update command..."
    list_id=$(echo "$existingList" | jq -r '.list_id')
    updateCommand="databricks ip-access-lists update $list_id --json '{\"label\":\"$LABEL\",\"list_type\":\"ALLOW\",\"ip_addresses\":[$ipAddressesJson]}'"
    echo "Updating existing IP access list with label '$LABEL':"
else
    # If the list doesn't exist, create a new one
    echo "No existing list found. Preparing create command..."
    createCommand="databricks ip-access-lists create --json '{\"label\":\"$LABEL\",\"list_type\":\"ALLOW\",\"ip_addresses\":[$ipAddressesJson]}'"
    echo "Creating new IP access list with label '$LABEL':"
fi

# Execute the command
echo "Executing command..."
if [ -n "$existingList" ]; then
    #echo "update command"
    eval "$updateCommand"
else
    #echo "create command"
    #echo $createCommand
    eval "$createCommand"
fi

echo "Script execution completed."