param (
    [Parameter(Mandatory=$true)]
    [string]
    $ClearResourceGroupName
)

$ServicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint | Write-Verbose

$StorageAccountKey = Get-AutomationVariable -Name 'storageKey'
$StorageAccountName = "jegebhaastorage"
$StorageFileName = "clearRG.template.json"

$Context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
Get-AzureStorageFileContent -ShareName 'arm-templates' -Context $Context -path $StorageFileName -Destination 'C:\Temp'
$TemplatePath = Join-Path -Path 'C:\Temp' -ChildPath $StorageFileName

$deployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $ClearResourceGroupName -Mode Complete -TemplateFile $templatePath -Force

$mailParams = @{
"RunbookName" = "runbook-clearResourceGroup";
"MessageBody" = $deployment;
"mailTo" = "v-jegebh@microsoft.com";
"mailFrom" = "v-jegebh@microsoft.com";
}

Start-AzureRmAutomationRunbook -ResourceGroupName "jegebhaaRG" -Name "runbook-sendMail" -AutomationAccountName "jegebhaa" -Parameters $mailParams

