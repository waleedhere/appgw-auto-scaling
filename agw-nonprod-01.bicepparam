using './main.bicep'

param environment = 'acc'
param filename1 = 'IncreaseMin_agw-nonprod-01'
param filename2 = 'DecreaseMin_agw-nonprod-01'
param applicationGatewayName = 'agw-nonprod-01'
param num = 1

param peerings =    [
    {
    resourceGroupName: 'prdrgwehub01'
    remoteVnetName: 'prdvnetwehub01'
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    }
  ]
