<#
    Script to test the PowerShell script New-LogicAppDoc.ps1 using a json file with the Logic App Workflow configuration
#>

$params = @{
    EnvironmentName = '839eace6-59ab-4243-97ec-a5b8fcc104e4'
    PowerAutomateName     = 'Teams Chat birthday message bot flow - BirthDay Test Chat Group - SharePoint List'
    OutputPath       = '..\examples\'
    Verbose          = $false
    Debug            = $false
}

. ..\src\New-PowerAutomateDoc.ps1 @params