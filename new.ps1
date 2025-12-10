# Parameters
$resourceGroupName = "DevOps"
$location = "eastus2"                           # Static Web Apps supported regions
$staticWebAppName = "devopsangularapp"          # globally unique name
$repoUrl = "https://github.com/mbutterfieldGO/DevOpsAngularStatic"  # GitHub repo URL
$branch = "main"                                # branch to deploy from
$appLocation = "/"                              # root of Angular project
$outputLocation = "dist/DevOpsAngularStatic"    # Angular build output folder
$sku = "Free"                                   # Free or Standard

# 1. Create resource group (if it doesn't exist)
if (-not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Output "Creating resource group $resourceGroupName in $location..."
    New-AzResourceGroup -Name $resourceGroupName -Location $location | Out-Null
} else {
    Write-Output "Resource group $resourceGroupName already exists."
}

# 2. Create Static Web App (linked to GitHub repo)
Write-Output "Creating Azure Static Web App $staticWebAppName..."
New-AzStaticWebApp `
    -ResourceGroupName $resourceGroupName `
    -Name $staticWebAppName `
    -Location $location `
    -Sku $sku `
    -Branch $branch `
    -RepositoryUrl $repoUrl `
    -AppLocation $appLocation `
    -OutputLocation $outputLocation | Out-Null

# 3. Output endpoint
$staticWebApp = Get-AzStaticWebApp -ResourceGroupName $resourceGroupName -Name $staticWebAppName
$webEndpoint = $staticWebApp.DefaultHostname
Write-Output "Static Web App is available at: https://$webEndpoint"
