<#
    Script to test the PowerShell script New-LogicAppDoc.ps1 using a json file with the Logic App Workflow configuration
#>

$params = @{
    SubscriptionName = 'Visual Studio Enterprise'
    ResourceGroupName = 'jiraintegration-demo-rg'
    Location         = 'westeurope'
    FilePath         = '.\powerapp-flow.json'
    LogicAppName     = 'powerapp-flow-demo'
    OutputPath       = '.\examples\'
    Verbose          = $false
    Debug            = $false
}

. ..\src\New-LogicAppDoc.ps1 @params