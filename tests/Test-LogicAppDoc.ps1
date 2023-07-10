<#
    Script to test the PowerShell script New-LogicAppDoc.ps1 using a json file with the Logic App Workflow configuration
#>

$params = @{
    SubscriptionName = 'Visual Studio Enterprise'
    Location         = 'westeurope'
    FilePath         = 'C:\Github\logicappdocs\examples\logic-jiraintegration-demo.json'
    LogicAppName     = 'logic-jiraintegration-demo'
    OutputPath       = 'C:\temp\'
    Verbose          = $false
    Debug            = $false
}

. "C:\Github\logicappdocs\src\New-LogicAppDoc.ps1" @params