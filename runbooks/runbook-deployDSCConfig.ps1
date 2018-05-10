param (
    [Parameter(Mandatory=$true)]
    [string]
    $ConfigFileName
)

$ServicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint | Write-Verbose

$StorageAccountKey = Get-AutomationVariable -Name 'storageKey'

$Context = New-AzureStorageContext -StorageAccountName 'jegebhaastorage' -StorageAccountKey $StorageAccountKey
Get-AzureStorageFileContent -ShareName 'dsc-configs' -Context $Context -path $ConfigFileName -Destination 'C:\Temp'
$TemplatePath = Join-Path -Path 'C:\Temp' -ChildPath $ConfigFileName

$deployment = Import-AzureRmAutomationDscConfiguration -AutomationAccountName "jegebhAutomationAccount" -ResourceGroupName "jegebhAutomationRG" -SourcePath $TemplatePath -Published -Force

$mailParams = @{
"RunbookName" = "runbook-deployDSCConfig";
"MessageBody" = $deployment;
"MailTo" = "v-jegebh@microsoft.com";
"MailFrom" = "v-jegebh@microsoft.com";
}

Start-AzureRmAutomationRunbook -ResourceGroupName "jegebhAutomationRG" -Name "runbook-sendMail" -AutomationAccountName "jegebhAutomationAccount" -Parameters $mailParams