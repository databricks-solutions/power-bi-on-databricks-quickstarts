# Databricks notebook source
# MAGIC %md
# MAGIC ### Obtain Updated Download Link
# MAGIC The download link at https://www.microsoft.com/en-us/download/details.aspx?id=56519 changes periodically so the `download_url` parameter below needs to be updated.

# COMMAND ----------

# MAGIC %pip install beautifulsoup4

# COMMAND ----------

import requests
import json
import ipaddress
from databricks.sdk import WorkspaceClient
from databricks.sdk.service import settings

# COMMAND ----------

import requests
from bs4 import BeautifulSoup
import re

def get_azure_download_link():
    url = "https://www.microsoft.com/en-us/download/details.aspx?id=56519"
    method_used = None
    
    try:
        # Send GET request to the webpage
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        # Parse the HTML content
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Method 1: Look for the actual download link in the page
        download_links = []
        
        # Check for links containing the JSON file pattern
        for link in soup.find_all('a', href=True):
            href = link['href']
            if 'ServiceTags_Public_' in href and '.json' in href:
                download_links.append(href)
        
        if download_links:
            method_used = "Method 1"
            return download_links[0], method_used
        
        # Method 2: Construct the download URL based on known pattern
        # From the search results, we know the current file is ServiceTags_Public_20250616.json
        file_name_match = re.search(r'ServiceTags_Public_\d{8}\.json', response.text)
        if file_name_match:
            file_name = file_name_match.group(0)
            # The actual download URL pattern for Microsoft downloads
            download_link = f"https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/{file_name}"
            method_used = "Method 2"
            return download_link, method_used
        
        # Method 3: Try to find download button and extract onclick or data attributes
        download_button = soup.find('a', class_=re.compile(r'download', re.I))
        if download_button:
            onclick = download_button.get('onclick', '')
            if 'ServiceTags_Public_' in onclick:
                file_match = re.search(r'ServiceTags_Public_\d{8}\.json', onclick)
                if file_match:
                    method_used = "Method 3"
                    return f"https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/{file_match.group(0)}", method_used
        
        return None, method_used
        
    except requests.RequestException as e:
        print(f"Error fetching the webpage: {e}")
        return None, method_used

# Get the download link
download_url, method = get_azure_download_link()
if download_url:
    print(f"Download link: {download_url}")
    print(f"Method used: {method}")
else:
    print("Could not extract download link")

# COMMAND ----------


label = "powerbi"

# COMMAND ----------

# MAGIC %md
# MAGIC ### Download the Power BI IPs

# COMMAND ----------

# List of services we're interested in
target_services = [
"PowerBI"
]
# "PowerPlatformInfra.WestUS",
# "PowerPlatformPlex.WestUS",
# "PowerQueryOnline.WestUS",

# COMMAND ----------

def get_powerbi_ips():
    # URL of the JSON file
    url = download_url

    # Download the JSON file
    response = requests.get(url)
    data = response.json()
    
    # Filter the IP addresses
    filtered_ips = []

    for value in data["values"]:
        if any(service in value["name"] for service in target_services):
            for address_prefix in value["properties"]["addressPrefixes"]:
                # Filter out IPv6 addresses
                try:
                    ip = ipaddress.ip_network(address_prefix)
                    if ip.version == 4:
                        filtered_ips.append(address_prefix)
                except ValueError:
                    # Skip invalid IP addresses
                    pass

    # Remove duplicates and sort the list
    filtered_ips = sorted(list(set(filtered_ips)))
    return filtered_ips

# COMMAND ----------

filtered_ips = get_powerbi_ips()

# COMMAND ----------

# MAGIC %md
# MAGIC ### Create Power BI IP Access Lists

# COMMAND ----------

def list_ip_access_lists():
    w = WorkspaceClient()
    all_lists = w.ip_access_lists.list()
    return all_lists

# COMMAND ----------

def get_filtered_list_id(list, label):
    filtered_list_id = None
    for ip_list in list:
        if ip_list.label == label:
            filtered_list_id = [True, ip_list.list_id]
            break
        else:
            filtered_list_id = [False, "0"]

    return filtered_list_id

# COMMAND ----------

def update_ip_access_list(exists, powerbi_list_id, filtered_ips):
    w = WorkspaceClient()
    if exists:
        replaced = w.ip_access_lists.replace(ip_access_list_id=powerbi_list_id,
                                             label=label,
                                             enabled=True,
                                             ip_addresses=filtered_ips,
                                             list_type=settings.ListType.ALLOW)
        print("Updated")
        return replaced
    else:
        created = w.ip_access_lists.create(label=label,
                                           ip_addresses=filtered_ips,
                                           list_type=settings.ListType.ALLOW)
        print("Created")
        return created

# COMMAND ----------

all_list = list_ip_access_lists()

# COMMAND ----------

list_id = get_filtered_list_id(all_list, label)

# COMMAND ----------

update_list = update_ip_access_list(list_id[0], list_id[1], filtered_ips)
update_list