param (
    [Parameter(Mandatory=$true)]
    [string]
    $DeployToResourceGroupName
)

$ServicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint | Write-Verbose

$StorageAccountKey = Get-AutomationVariable -Name 'storageKey'
$sshPubKey = Get-AutomationVariable -Name 'jegebhSSHPubKey'

$Context = New-AzureStorageContext -StorageAccountName 'jegebhaastorage' -StorageAccountKey $StorageAccountKey
Get-AzureStorageFileContent -ShareName 'arm-templates' -Context $Context -path 'deployLinuxVm.template.json' -Destination 'C:\Temp'
$TemplatePath = Join-Path -Path 'C:\Temp' -ChildPath 'deployLinuxVm.template.json'

$deployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $DeployToResourceGroupName -sshKeyData $sshPubKey -TemplateFile $TemplatePath

$mailParams = @{
"RunbookName" = "runbook-deployLinuxVm";
"MessageBody" = $deployment;
"MailTo" = "v-jegebh@microsoft.com";
"MailFrom" = "v-jegebh@microsoft.com";
}

Start-AzureRmAutomationRunbook -ResourceGroupName "jegebhaaRG" -Name "runbook-sendMail" -AutomationAccountName "jegebhaa" -Parameters $mailParams