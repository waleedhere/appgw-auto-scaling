# Define variables
$ResourceGroup = "prdrgwehub01"
$AppGWName = "agw-nonprod-01"

# Authenticate with Azure using managed identity
Connect-AzAccount -Identity 

# Get the Application Gateway
$gw = Get-AzApplicationGateway -Name $AppGWName -ResourceGroupName $ResourceGroup

# Set the autoscale configuration to 2 instances
$gw = Set-AzApplicationGatewayAutoscaleConfiguration -ApplicationGateway $gw -MinCapacity 10

# Update the Application Gateway
$gw = Set-AzApplicationGateway -ApplicationGateway $gw

Write-Output "Application Gateway scaling to 10 instance(s) has been successfully configured."
