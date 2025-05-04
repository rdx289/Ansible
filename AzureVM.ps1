# Login to Azure account
Connect-AzAccount

# Set variables for the VM
$resourceGroupName = "MyResourceGroup"
$location = "eastus"
$vmName = "MyUbuntuVM"
$image = "Canonical:UbuntuServer:18.04-LTS:latest" # Specify the full image reference
$adminUsername = "azureuser"
$adminPassword = ConvertTo-SecureString "P@ssw0rd1234!" -AsPlainText -Force # Ensure this meets Azure's password complexity requirements
$size = "Standard_B1s" # Free tier eligible size

# Create a resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $size |
    Set-AzVMOperatingSystem -Linux -ComputerName $vmName -Credential (New-Object System.Management.Automation.PSCredential($adminUsername, $adminPassword)) |
    Set-AzVMSourceImage -PublisherName "Canonical" -Offer "UbuntuServer" -Sku "18.04-LTS" -Version "latest" |
    Add-AzVMNetworkInterface -Id (New-AzNetworkInterface -Name "$vmName-NIC" -ResourceGroupName $resourceGroupName -Location $location -SubnetId (New-AzVirtualNetwork -Name "$vmName-VNet" -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix "10.0.0.0/16" | Add-AzVirtualNetworkSubnetConfig -Name "default" -AddressPrefix "10.0.0.0/24" | Set-AzVirtualNetwork).Subnets[0].Id).Id

# Create the virtual machine
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

# Open port 22 for SSH access
$nsRule = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH" -Protocol "Tcp" -Direction "Inbound" -Priority 1000 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "22" -Access "Allow"
$nsGroup = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$vmName-NSG" -SecurityRules $nsRule
Set-AzNetworkInterface -NetworkInterface (Get-AzNetworkInterface -Name "$vmName-NIC" -ResourceGroupName $resourceGroupName) -NetworkSecurityGroup $nsGroup

Write-Host "Ubuntu VM created successfully. You can SSH into it using the public IP address."