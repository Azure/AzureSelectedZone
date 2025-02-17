# Deployment script
param([Parameter(Mandatory=$true)] [String]$Location,
    [Parameter(Mandatory=$true)][String]$SubscriptionId,
    [Parameter(Mandatory=$true)][String]$ResourceGroupName,
    [Parameter(Mandatory=$true)][String]$VirtualMachineName,
    [Parameter(Mandatory=$true)][String]$TemplateFile,
    [Parameter(Mandatory=$true)][String]$TemplateParameterFile,
    [Parameter(Mandatory=$true)][String]$VirtualNetworkName
    )
Connect-AzAccount
Set-AzContext -Subscription $SubscriptionId
New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
$frontendSubnet = New-AzVirtualNetworkSubnetConfig -Name sub1 -AddressPrefix "10.0.0.0/24"
New-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName `
    -Location $Location -AddressPrefix "10.0.0.0/16" -Subnet $frontendSubnet
New-AzResourceGroupDeployment -Name $VirtualMachineName -ResourceGroupName $ResourceGroupName -VirtualMachineName $VirtualMachineName -Location $Location -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile -virtualNetworkName $VirtualNetworkName -subnetName sub1 -Verbose