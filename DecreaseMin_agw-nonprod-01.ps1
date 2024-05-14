# Define variables
$ResourceGroup = "prdrgwehub01"
$AppGWName = "agw-nonprod-01"

# Authenticate with Azure using managed identity
Connect-AzAccount -Identity 

# Get the Application Gateway
$gw = Get-AzApplicationGateway -Name $AppGWName -ResourceGroupName $ResourceGroup

# Set the autoscale configuration to 1 instance
$gw = Set-AzApplicationGatewayAutoscaleConfiguration -ApplicationGateway $gw -MinCapacity 1

# Update the Application Gateway
$gw = Set-AzApplicationGateway -ApplicationGateway $gw

Write-Output "Application Gateway scaling to 1 instances has been successfully configured."