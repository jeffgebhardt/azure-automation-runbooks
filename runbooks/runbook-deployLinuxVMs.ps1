param (
    [Parameter(Mandatory=$true)]
    [string]
    $DeployToResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]
    $NumInstances
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
Get-AzureStorageFileContent -ShareName 'arm-templates' -Context $Context -path 'azureDeploy.template.json' -Destination 'C:\Temp'
$TemplatePath = Join-Path -Path 'C:\Temp' -ChildPath 'azureDeploy.template.json'

$deployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $DeployToResourceGroupName -numberOfInstances $NumInstances -sshKeyData $sshPubKey -TemplateFile $TemplatePath

$mailParams = @{
"RunbookName" = "deployLinuxVMs";
"MessageBody" = $deployment
}

Start-AzureRmAutomationRunbook -ResourceGroupName "jegebhAutomationRG" -Name "runbook-sendMail" -AutomationAccountName "jegebhAutomationAccount" -Parameters $mailParams