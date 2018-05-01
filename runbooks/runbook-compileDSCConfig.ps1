param (
    [Parameter(Mandatory=$true)]
    [string]
    $DscConfigName
)

$ServicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint | Write-Verbose

$CompilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName "jegebhDevRG" -AutomationAccountName "jegebhAutomationAccount" -ConfigurationName $DscConfigName

while($CompilationJob.EndTime –eq $null -and $CompilationJob.Exception –eq $null)
{
    $CompilationJob = $CompilationJob | Get-AzureRmAutomationDscCompilationJob
    Start-Sleep -Seconds 3
}

$mailParams = @{
"RunbookName" = "runbook-deployDSCConfig";
"MessageBody" = $CompilationJob
}

Start-AzureRmAutomationRunbook -ResourceGroupName "jegebhDevRG" -Name "runbook-sendMail" -AutomationAccountName "jegebhAutomationAccount" -Parameters $mailParams