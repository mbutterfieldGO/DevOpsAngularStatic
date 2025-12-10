# Parameters - edit as needed
$resourceGroupName = "DevOps"
$location = "eastus"
$storageAccountName = "devopsangularstorage"   # must be globally unique, lowercase, 3-24 chars
$sku = "Standard_LRS"
$kind = "StorageV2"                             # required for static website
$indexDocument = "index.html"
$errorDocument = "index.html"                   # common for SPAs to fallback to index.html
$distPath = "C:\development\DevOpsAngularStatic\dist\DevOpsAngularStatic"  # path to built Angular output

# 1. Create resource group (if it doesn't exist)
if (-not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Output "Creating resource group $resourceGroupName in $location..."
    New-AzResourceGroup -Name $resourceGroupName -Location $location | Out-Null
} else {
    Write-Output "Resource group $resourceGroupName already exists."
}

# 2. Create storage account (StorageV2) with public blob access allowed
Write-Output "Creating storage account $storageAccountName..."
New-AzStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $storageAccountName `
    -Location $location `
    -SkuName $sku `
    -Kind $kind `
    -EnableHttpsTrafficOnly $true `
    -AllowBlobPublicAccess $true | Out-Null

# 3. Get storage account key and create context
$key = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName)[0].Value
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $key

# 4. Enable static website hosting
Write-Output "Enabling static website (Index: $indexDocument, Error: $errorDocument)..."
Enable-AzStorageStaticWebsite -Context $ctx -IndexDocument $indexDocument -ErrorDocument404Path $errorDocument

# 5. Upload contents of the dist folder to $web container
if (-not (Test-Path -Path $distPath)) {
    throw "Dist path not found: $distPath. Build your Angular app first (ng build) and set \$distPath accordingly."
}
Write-Output "Uploading files from $distPath to \$web container..."
Get-ChildItem -Path $distPath -Recurse -File | ForEach-Object {
    # Compute relative path and convert backslashes to forward slashes for blob names
    $relativePath = $_.FullName.Substring($distPath.Length + 1) -replace '\\','/'
    Set-AzStorageBlobContent -File $_.FullName -Container '$web' -Blob $relativePath -Context $ctx -Force | Out-Null
}

# 6. Output website endpoint
$storage = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
$webEndpoint = $storage.PrimaryEndpoints.Web
Write-Output "Static website is available at: $webEndpoint"