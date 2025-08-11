# Databricks notebook source
# MAGIC %md
# MAGIC ### Turn on/off the Workspace IP Access List   
# MAGIC The following SDK calls can turn on or turn off the Workspace IP Access list as desired.

# COMMAND ----------

from databricks.sdk import WorkspaceClient
from databricks.sdk.service import settings

def enabled_ip_access(enable: bool):
    # Create a WorkspaceClient instance
    w = WorkspaceClient()
    
    # Get the current status of IP access lists
    conf = w.workspace_conf.get_status(keys="enableIpAccessLists")
    conf = conf["enableIpAccessLists"]
    print("Current status is: " + conf)

    # Check if IP access lists are already enabled and the request is to enable
    if conf == "true" and enable == True:
        print("Already enabled")

    # Check if IP access lists are already disabled and the request is to disable
    if conf == "false" and enable == False:
        print("Already disabled")

    # Disable IP access lists if they are currently enabled and the request is to disable
    if conf == "true" and enable == False:
        conf_disable = w.workspace_conf.set_status({"enableIpAccessLists": "false"})
        print("Disabled")

    # Enable IP access lists if they are currently disabled and the request is to enable
    elif conf == "false" and enable == True:
        conf_enabled = w.workspace_conf.set_status({"enableIpAccessLists": "true"})
        print("Enabled")

# COMMAND ----------

enabled_ip_access(True)