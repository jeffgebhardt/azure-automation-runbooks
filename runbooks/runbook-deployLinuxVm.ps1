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
}

Start-AzureRmAutomationRunbook -ResourceGroupName "jegebhAutomationRG" -Name "runbook-sendMail" -AutomationAccountName "jegebhAutomationAccount" -Parameters $mailParams
