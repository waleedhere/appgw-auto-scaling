@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the environment (e.g. dev, tst, acc or prd)')
@minLength(2)
@maxLength(7)
param environment string
param filename1 string
param filename2 string
param applicationGatewayName string
param num int

var subnetConName = 'snet-dep-con'
var subnetStsFileName = 'snet-blob-file'
var stsFileSubnetAddPrefix = '10.52.137.0/29'
var autovnetAddressPrefix = '10.52.136.0/22'
var conSubnetAddPrefix = '10.52.136.0/29'
var subnetOperatorName = 'Subnet Joiner'
var deployScriptName = 'deployment-script-minimum-privilege-for-deployment-principal'
var vnetNameProd = 'prdvnetwehub01'
var automationAccountName = 'automationaccount'
var storageAccountName = 'stsautomationacc'
var containerName = 'scripts'
var privateEndpointstorageaccNameFile = 'pe-stsacc-file'
var vnetNameAutomation = 'vnet-automation'

@description('Friendly name of the role definition')
var roleDefinitionNameForDeployScript = guid(
  subscription().id,
  string(actionsForDeployScript),
  string(notActionsForDeployScript),
  string(dataActionsForDeployScript),
  string(notDataActionsForDeployScript)
)

@description('Array of actions for the roleDefinition')
var actionsForDeployScript = [
  'Microsoft.Storage/storageAccounts/*'
  'Microsoft.ContainerInstance/containerGroups/*'
  'Microsoft.Resources/deployments/*'
  'Microsoft.Resources/deploymentScripts/*'
]
var notActionsForDeployScript = []
var dataActionsForDeployScript = []
var notDataActionsForDeployScript = []


@description('Deployment Scripts Role')
var roleDefinitionName = guid(
  subscription().id,
  string(actions),
  string(notActions),
  string(dataActions),
  string(notDataActions)
)

@description('actions for the roleDefinition to perform Scaling operation')
var actions = [
  'Microsoft.Network/virtualNetworks/subnets/join/action'
]
var notActions = []
var dataActions = []
var notDataActions = []

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-09-01' existing = {
  name: applicationGatewayName
}

resource virtualNetworkProd 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetNameProd
}

resource managedIdentitydeployscript 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'mi-deploy-script-${environment}'
  location: location
}

resource subnetOpsCustomRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleDefinitionName
  properties: {
    roleName: subnetOperatorName
    description: 'access on subnet'
    type: 'customRole'
    permissions: [
      {
        actions: actions
        notActions: notActions
        notDataActions: notDataActions
      }
    ]
    assignableScopes: [
      '/subscriptions/9501d39e-dfe8-4e41-9e23-0853b5d645d9/resourcegroups/${resourceGroup().name}'
    ]
  }
}

resource deployScriptCustomRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' = {
  name: roleDefinitionNameForDeployScript
  properties: {
    roleName: deployScriptName
    description: 'Configure least privilege for the deployment principal in deployment script'
    type: 'customRole'
    permissions: [
      {
        actions: actionsForDeployScript
        notActions: notActionsForDeployScript
        notDataActions: notDataActionsForDeployScript
      }
    ]
    assignableScopes: [
      '/subscriptions/9501d39e-dfe8-4e41-9e23-0853b5d645d9/resourcegroups/${resourceGroup().name}'
    ]
  }
}

resource storageFileDataPrivilegedContributorRef 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '69566ab7-960f-475b-8e7c-b3118f30c6bd' // Storage File Data Privileged Contributor
  scope: storageAccount
}

resource storageBlobDataPrivilegedOwnerRef 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Privileged Owner
  scope: storageAccount
}

resource deployscriptAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('DeployScript', storageAccountName, subscription().subscriptionId, uniqueString(resourceGroup().id))
  scope: storageAccount
  properties: {
    principalType: 'ServicePrincipal'
    principalId: managedIdentitydeployscript.properties.principalId
    roleDefinitionId: deployScriptCustomRoleDefinition.id
  }
}

resource deployscriptAssignment1 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('storageFileDataPrivilegedContributorRole', storageAccountName, subscription().subscriptionId, uniqueString(resourceGroup().id))
  scope: storageAccount
  properties: {
    principalType: 'ServicePrincipal'
    principalId: managedIdentitydeployscript.properties.principalId
    roleDefinitionId: storageFileDataPrivilegedContributorRef.id
  }
}

resource networkContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: applicationGateway
  name: '4d97b98b-1d4f-4787-a291-c67834d212e7'
}

resource subnetOperatorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('SubnetJoiner', vnetNameProd, subscription().subscriptionId, uniqueString(resourceGroup().id))
  scope: virtualNetworkProd
  properties: {
    principalType: 'ServicePrincipal'
    principalId: automationAccount.identity.principalId
    roleDefinitionId: subnetOpsCustomRoleDefinition.id
  }
}

resource networkContributorAssignmnet 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('NetworkContributor', applicationGatewayName, subscription().subscriptionId, uniqueString(resourceGroup().id))
  scope: applicationGateway
  properties: {
    principalType: 'ServicePrincipal'
    principalId: automationAccount.identity.principalId
    roleDefinitionId: networkContributorRoleDefinition.id
  }
}

resource automationAccountAssignmentStorage 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageBloblOwnerAutomation', storageAccountName, subscription().subscriptionId, uniqueString(resourceGroup().id))
  scope: storageAccount
  properties: {
    principalType: 'ServicePrincipal'
    principalId: automationAccount.identity.principalId
    roleDefinitionId: storageBlobDataPrivilegedOwnerRef.id
  }
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowSharedKeyAccess: true
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
      virtualNetworkRules: [ 
        {
          id: '${virtualNetworkAutomation.id}/subnets/${subnetConName}'
          action: 'Allow'
          state: 'Succeeded'
          }
      ] 
    }
  }
  resource blobSerivce 'BlobServices' = {
    name: 'default'

    resource container 'containers' = {
      name: containerName
      properties: {
        publicAccess: 'Blob'
      }
    }
  }

}

resource virtualNetworkAutomation 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: vnetNameAutomation
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        autovnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetConName
        properties:{
        addressPrefix: conSubnetAddPrefix
        serviceEndpoints: [
          {
            service: 'Microsoft.Storage'
          }
        ]
        delegations: [
          {
            name: 'containerDelegation'
            properties: {
              serviceName: 'Microsoft.ContainerInstance/containerGroups'
            }
          }
        ]
        }
      }
      {
        name: subnetStsFileName
        properties:{
        addressPrefix: stsFileSubnetAddPrefix
        }
      }
    ]
    }
  }

  resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
    name: 'privatelink.file.core.com'
  }
  
  resource arecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: storageAccountName
  parent: dnsZone
  etag: 'string'
  properties: {
    aRecords: [
      {
        ipv4Address: '10.52.136.0'
      }
    ]
  }
}

resource privateEndpointStorageAccFile 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: privateEndpointstorageaccNameFile
  location: location
  properties: {
    customNetworkInterfaceName: 'pe-nic-storageAccFile'
    privateLinkServiceConnections: [
      {
        name: storageAccountName
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
    subnet: {
      id: virtualNetworkAutomation.properties.subnets[1].id
    }
  }
}
resource deploymentScriptIncreaseScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'deployscript-upload-blob-${filename1}'
  dependsOn: [
    privateEndpointStorageAccFile
  ]
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentitydeployscript.id}':{
      }
    }
  }
  properties: {
    storageAccountSettings: {
      storageAccountName: storageAccountName
    }
    containerSettings: {
      subnetIds: [ 
        {
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkAutomation.name, subnetConName)
        } 
      ]
    } 
    azCliVersion: '2.26.1'
    retentionInterval: 'P1D'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'CONTENT1'
        value: loadTextContent('IncreaseMin_agw-nonprod-01.ps1')
      }
    ]
    scriptContent: 'echo "$CONTENT${num}" > ${filename1}.ps1 && az storage blob upload -f ${filename1}.ps1 -c ${containerName} -n ${filename1}.ps1'

  }
}
resource deploymentScriptDecreaseScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'deployscript-upload-blob-${filename2}'
  dependsOn: [
    privateEndpointStorageAccFile
  ]
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentitydeployscript.id}':{}
    }
  }
  properties: {
    storageAccountSettings: {
      storageAccountName: storageAccountName
    }
    containerSettings: {
      subnetIds: [ 
        {
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkAutomation.name, subnetConName)
        } 
      ]
    }
    azCliVersion: '2.26.1'
    retentionInterval: 'P1D'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
    ]
     scriptContent: 'echo "$CONTENT${num}" > ${filename2}.ps1 && az storage blob upload -f ${filename2}.ps1 -c ${containerName} -n ${filename2}.ps1'
  }
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: automationAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: false
    sku: {
      name: 'Basic'
    }
  }
}

resource automationRunbookIncrease 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: filename1
  location: location
  properties: {
    description: 'To increase the number of instance of App Gateway'
    logActivityTrace: 1
    logVerbose: true
    logProgress: true
    runbookType: 'PowerShell7'
    publishContentLink: {
      // uri: 'https://stsautomationacc.blob.core.windows.net/scripts/IncreaseMin_agw-nonprod-01.ps1'
      uri: 'https://stsautomationacc.blob.${az.environment().suffixes.storage}/scripts/${filename1}.ps1'
      version: '1.0.0.0'
    }
  }
  dependsOn: [
    deploymentScriptIncreaseScript
  ]
}
resource automationRunbookDecrease 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: filename2
  location: location
  properties: {
    description: 'To decrease the number of instance of App Gateway'
    logActivityTrace: 1
    logVerbose: true
    logProgress: true
    runbookType: 'PowerShell7'
    publishContentLink: {
      // uri: 'https://stsautomationacc.blob.core.windows.net/scripts/DecreaseMin_agw-nonprod-01.ps1'
      uri: 'https://stsautomationacc.blob.${az.environment().suffixes.storage}/scripts/${filename2}.ps1'
      version: '1.0.0.0'
    }
  }
  dependsOn: [
    deploymentScriptDecreaseScript
  ]
}
resource automationScheduleIncrease 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  parent: automationAccount
  name: filename1
  properties: {
    frequency: 'Day'
    interval: '1'
    startTime: '2024-05-15T05:00:00+00:00'
    timeZone: 'Europe/Amsterdam'
  }
}
resource automationScheduleDecrease 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  parent: automationAccount
  name: filename2
  properties: {
    frequency: 'Day'
    interval: '1'
    startTime: '2024-05-15T23:00:00+02:00'
    timeZone: 'Europe/Amsterdam'
  }
}
resource automationaccount_Increasejobsschedule 'Microsoft.Automation/automationAccounts/jobSchedules@2023-11-01' = {
  name: guid(uniqueString(deploymentScriptDecreaseScript.id))
  parent: automationAccount
  properties: {
    runbook: {
      name: automationRunbookIncrease.name
    }
    schedule: {
      name: automationScheduleIncrease.name
    }
  }
}
resource automationaccount_Decreasejobsschedule 'Microsoft.Automation/automationAccounts/jobSchedules@2023-05-15-preview' = {
  name: guid(uniqueString(deploymentScriptIncreaseScript.id))
  parent: automationAccount
  properties: {
    runbook: {
      name: automationRunbookDecrease.name
    }
    schedule: {
      name: automationScheduleDecrease.name
    }
  }
}

resource deploymentScriptStorage 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'deployscript-storage'
  dependsOn: [
    privateEndpointStorageAccFile
    automationRunbookDecrease
    automationRunbookIncrease
  ]
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentitydeployscript.id}':{}
    }
  }
  properties: {
    storageAccountSettings: {
      storageAccountName: storageAccountName
    }
    containerSettings: {
      subnetIds: [ 
        {
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkAutomation.name, subnetConName)
        } 
      ]
    }
    azCliVersion: '2.26.1'
    retentionInterval: 'P1D'
     scriptContent: 'az storage account update --name ${storageAccountName} --default-action Deny'
  }
}
