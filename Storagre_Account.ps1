if (import-module -name Az -ErrorAction SilentlyContinue) {
    Write-Host "Module Az.Storage is already imported." 
    <# Action to perform if the condition is true #>
} else {
    install-module -name Az -AllowClobber -Force -Scope CurrentUser
    Write-Host "Module Az.Storage is not installed. Installing now..."
}

Connect-AzAccount
$resourceGroupName = "myResourceGroup"
$location = "East US"
$storageAccountName = "t3sts7r0ag3"
$skuName = "Standard_LRS"
$kind = "StorageV2"
$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName $skuName -Kind $kind
$storageAccount | Format-List
$storageAccountKey = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName
$storageAccountKey | Format-List
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey[0].Value
$containerName = "mycontainer"
$container = New-AzStorageContainer -Name $containerName -Context $context -Permission Off
$container | Format-List
$blobName = "myblob.txt"
$blobContent = "Hello, Azure Storage!"
$blob = Set-AzStorageBlobContent -File $blobName -Container $containerName -Context $context
$blob | Format-List
$blobContent = Get-AzStorageBlobContent -Blob $blobName -Container $containerName -Context $context