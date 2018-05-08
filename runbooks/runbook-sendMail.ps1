Param (
    # Input parameters
    [Parameter (Mandatory = $true)]
    [string] 
    $RunbookName,
 
    [Parameter (Mandatory = $true)]
    [object] 
    $MessageBody,

    [Parameter (Mandatory = $true)]
    [string]
    $mailTo,

    [Parameter (Mandatory = $true)]
    [string]
    $mailFrom
  )
 
$O365Credential = Get-AutomationPSCredential -Name "mailCred"
     
$Message = New-Object System.Net.Mail.MailMessage
         
$Message.From = $mailFrom
$Message.replyTo = $mailFrom
$Message.To.Add($mailTo)
   
$Message.SubjectEncoding = ([System.Text.Encoding]::UTF8)
$Message.Subject = "Runbook job: $($RunbookName) | Deployment state: $($MessageBody.ProvisioningState)"
         
$Message.Body = "ARM Template Name: $($MessageBody.DeploymentName) `
                 <br /> Deployment state: $($MessageBody.ProvisioningState) `
                 <br /> Resource Group: $($MesssageBody.ResourceGroupName) `
                 <br /> CorrelationId: $($MesssageBody.CorrelationId) `
                 <br /> Deployment time: $($MessageBody.TimeStamp) `
                 <br /> Outputs: $($MessageBody.OutputsString) "
$Message.BodyEncoding = ([System.Text.Encoding]::UTF8)
$Message.IsBodyHtml = $true
         
$SmtpClient = New-Object System.Net.Mail.SmtpClient 'smtp.office365.com', 587
$SmtpClient.Credentials = $O365Credential
$SmtpClient.EnableSsl   = $true
   
$SmtpClient.Send($Message)