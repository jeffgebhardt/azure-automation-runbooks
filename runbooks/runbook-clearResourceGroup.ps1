param (
    [Parameter(Mandatory=$true)]
    [string]
    $ClearResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]
    $StorageAccountName,

    [Parameter(Mandatory=$true)]
    [string]
    $StorageFileName
)

$ServicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint | Write-Verbose

$StorageAccountKey = Get-AutomationVariable -Name 'storageKey'

$Context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
Get-AzureStorageFileContent -ShareName 'arm-templates' -Context $Context -path 'clearRG.template.json' -Destination 'C:\Temp'
$TemplatePath = Join-Path -Path 'C:\Temp' -ChildPath $StorageFileName

$deployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $ClearResourceGroupName -Mode Complete -TemplateFile $templatePath -Force

$mailParams = @{
"RunbookName" = "runbook-clearResourceGroup";
"MessageBody" = $deployment;
"mailTo" = "v-jegebh@microsoft.com";
"mailFrom" = "v-jegebh@microsoft.com";
}

Start-AzureRmAutomationRunbook -ResourceGroupName "jegebhAutomationRG" -Name "runbook-sendMail" -AutomationAccountName "jegebhAutomationAccount" -Parameters $mailParams

