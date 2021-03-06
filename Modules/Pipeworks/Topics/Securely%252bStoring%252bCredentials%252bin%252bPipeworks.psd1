@{
    Name = 'Securely Storing Credentials in Pipeworks'
    PSTypeName = 'http://shouldbeonschema.org/Topic'
    Content = (
                    ConvertFrom-Markdown @"
Because credential Storage is a pervasive problem in most development and deployment tasks, PowerShell Pipeworks includes a few functions to help store information securely.  


They are:
* Get-SecureSetting
* Add-SecureSetting
* Remove-SecureSetting


An example of storing a credential using these settings is below:
"@
                ) + (
                Write-ScriptHTML @'
Add-SecureSetting AStringSetting 'A String' 
'@)
    Related = "[Storing Secure Information Within the Pipeworks Manifest](/Topics/Storing Secure Information within the Pipeworks Manifest)"
}