# Application Gateway scheduled Auto-scaling
In the project we are implementing automatic schedule scaling for Azure Application Gateway using Azure Automation Account

List of resources and services we have utilizes in order achieve this:

1. Azure Automation Account
2. Azure Automation Runbook
3. Azure Automation Schedule/jobSchedule
4. Deployment Script
5. Virtual Network
6. Private DNS zone


## Implementation
In this use case scenario, Application Gateway is already provisioned with it's virtual network.

We are using custom Roles over the existing VNET of the App Gateway as well as the access on the Network Gateway itself.

The connection between storage account and all the other resources will be turned private after the *__deploymentScriptStorage__* resource.


We are creating Azure Automation Runbooks referenced from the Blob container, which is being upload from local machine through Deployment Script resource in Bicep.