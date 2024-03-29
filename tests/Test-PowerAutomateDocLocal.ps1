<#
    Script to test the PowerShell script New-PowerAutomateDoc.ps1 using a json file with the Logic App Workflow configuration
#>

$params = @{
    EnvironmentName   = '839eace6-59ab-4243-97ec-a5b8fcc104e4'
    PowerAutomateName = 'LocalPowerAutomate'
    OutputPath        = $($env:TEMP)
    FilePath          = 'c:\temp\DevSecOpsCapabilityFlow_20240328153930.zip'
    Verbose           = $true
    Debug             = $true
}

. ..\src\New-PowerAutomateDoc.ps1 @params