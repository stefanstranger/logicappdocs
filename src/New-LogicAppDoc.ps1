[CmdletBinding(DefaultParameterSetName = 'Azure')]
Param(
    [Parameter(Mandatory = $true,
        ParameterSetName = 'Azure')]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true,
        ParameterSetName = 'Local')]
    [string]$SubscriptionName,

    [Parameter(Mandatory = $true,
        ParameterSetName = 'Local')]
    [string]$Location,

    [Parameter(Mandatory = $true,
        ParameterSetName = 'Local')]
    [string]$FilePath,

    [Parameter(Mandatory = $true)]
    [string]$LogicAppName,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'


@"
╭──────────────────────╮
│    logicappdocs      │
╰──────────────────────╯

Author: Stefan Stranger
Github: https://github.com/stefanstranger/logicappdocs
Version: 1.0

"@.foreach({
        Write-Host $_ -ForegroundColor Magenta
    })

#region Import PowerShell Modules. Add more modules if needed
if (Get-Module -ListAvailable -Name PSDocs) {
    Write-Verbose -Message 'PowerShell Module PSDocs is already installed'
}
else {
    Write-Verbose 'Installing PowerShell Module PSDocs'
    Install-Module PSDocs -RequiredVersion 0.9.0 -Scope CurrentUser -Repository PSGallery -SkipPublisherCheck -Confirm:$false -Force | Out-Null
}
#endregion

#region Set Variables
$templateName = 'Azure-LogicApp-Documentation'
$templatePath = (Join-Path $PSScriptRoot 'LogicApp.Doc.ps1')
#endregion

#region Helper Functions
Function Get-Action {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $Actions,
        [Parameter(Mandatory = $false)]
        $Parent = $null
    )

    foreach ($key in $Actions.PSObject.Properties.Name) {
        $action = $Actions.$key
        $actionName = $key.Replace(' ', '_').Replace('(', '').Replace(')', '').Replace('@', '-at-')

        # new runafter code
        $runAfter = if (![string]::IsNullOrWhitespace($action.runafter)) {
            $action.runAfter.PSObject.Properties.Name.Replace(' ', '_').Replace('(', '').Replace(')', '').Replace('@', '-at-')
        }
        elseif (([string]::IsNullOrWhitespace($action.runafter)) -and $Parent) {
            # if Runafter is empty but has parent use parent.
            $Parent -replace '(-False|-True)', ''
        }
        else {
            # if Runafter is empty and has no parent use null.
            $null
        }
        
        $inputs = if ($action | Get-Member -MemberType Noteproperty -Name 'inputs') { 
            $($action.inputs)
        } 
        else { 
            $null 
        }

        $type = $action.type

        # new ChildActions code
        $childActions = if ($action | Get-Member -MemberType Noteproperty -Name 'Actions') { $action.Actions.PSObject.Properties.Name } else { $null }

        # Create PSCustomObject
        [PSCustomObject]@{
            ActionName   = $actionName
            RunAfter     = $runAfter
            Type         = $type
            Parent       = $Parent
            ChildActions = $childActions
            Inputs       = Remove-Secrets -Inputs $($inputs | ConvertTo-Json -Depth 10 -Compress)
        }

        if ($action.type -eq 'If') {
            # Check if the else property is present
            if ($action | Get-Member -MemberType Noteproperty -Name 'else') {
                # Get the actions for the true condition
                Get-Action -Actions $($action.Actions) -Parent ('{0}-True' -f $actionName)
                # Get the actions for the false condition
                Get-Action -Actions $($action.else.Actions) -Parent ('{0}-False' -f $actionName)
            }
            #When there is only action for the true condition
            else {
                Get-Action -Actions $($action.Actions) -Parent ('{0}-True' -f $actionName)
            }
        }

        # Recursively call the function for child actions
        elseif ($action | Get-Member -MemberType Noteproperty -Name 'Actions') {
            Get-Action -Actions $($action.Actions) -Parent $actionName
        }
    }   
}

Function Get-Connection {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $Connection
    )

    foreach ($key in $Connection.PSObject.Properties) {
        [PSCustomObject]@{
            Name                 = $key.name
            ConnectionId         = $key.Value.connectionId
            ConnectionName       = $key.Value.connectionName
            ConnectionProperties = if ($key.Value | Get-Member -MemberType NoteProperty connectionProperties) { $key.Value.connectionProperties } else { $null }
            id                   = $key.Value.id
        } 
    }
}
Function Remove-Secrets {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $Inputs
    )

    # Remove the secrets from the Logic App Inputs
    $regexPattern = '(\"headers":\{"Authorization":"(Bearer|Basic) )[^"]*'
    $Inputs -replace $regexPattern, '$1******'
}

Function Sort-Action {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $Actions
    )

    # Search for the action that has an empty RunAfter property
    $firstAction = $Actions | Where-Object { [string]::IsNullOrEmpty($_.RunAfter) } |
    Add-Member -MemberType NoteProperty -Name Order -Value 0 -PassThru
    $currentAction = $firstAction

    # Define a variable to hold the current order index
    $indexNumber = 1

    #Loop through all the actions 
    for ($i = 1; $i -lt $Actions.Count; $i++) {
        Write-Verbose -Message ('Processing currentaction {0}' -f $($currentAction.ActionName))
        # Search for the action that has the first action's ActionName in the RunAfter property or the previous action's ActionName
        if (![string]::IsNullOrEmpty($firstAction)) {
            $Actions | Where-Object { $_.RunAfter -eq $firstAction.ActionName } | 
            Add-Member -MemberType NoteProperty -Name Order -Value $indexNumber
            $currentAction = ($Actions | Where-Object { $_.RunAfter -eq $firstAction.ActionName })
            # Set the firstAction variable to null
            $firstAction = $null            
            $indexNumber++ 
        }
        else {
            # Search for actions that have the previous action's ActionName in the RunAfter property
            # If there are multiple actions with the same RunAfter property, set the RunAfter property to the Parent property
            if (($Actions | Where-Object { $_.RunAfter -eq $($currentAction.ActionName) } | Measure-Object).count -gt 1) {
                $Actions | Where-Object { $_.RunAfter -eq $($currentAction.ActionName) } | ForEach-Object {                     
                    # Check if the action has a Parent Value
                    if (![string]::IsNullOrEmpty($_.Parent)) {
                        Write-Verbose -Message ('Setting RunAfter property {0} to Parent property value {1} for action {2}' -f $_.RunAfter, $_.Parent, $_.ActionName)
                        $_.RunAfter = $_.Parent
                    }
                }
                # Iterate first the condition status true actions.
                if ($Actions | Where-Object { $_.RunAfter -eq $(('{0}-True') -f $($currentAction.ActionName)) }) {
                    $Actions | Where-Object { $_.RunAfter -eq $(('{0}-True') -f $($currentAction.ActionName)) }  |
                    Add-Member -MemberType NoteProperty -Name Order -Value $indexNumber 
                    $currentAction = $Actions | Where-Object { $_.RunAfter -eq $(('{0}-True') -f $($currentAction.ActionName)) } 
                    # Increment the indexNumber
                    $indexNumber++
                }   
                else {
                    # Add Order property to the action that it's RunAfter property updated from the Parent property.
                    # This is the first action in a foreach loop.
                    # After this action the rest of rest of the foreach actions need to be processed.
                    $Actions | Where-Object { $_.RunAfter -eq $($currentAction.ActionName) -and ($null -ne $($_.Parent)) } |
                    Add-Member -MemberType NoteProperty -Name Order -Value $indexNumber 
                    $currentAction = $Actions | Where-Object { $_.RunAfter -eq $($currentAction.ActionName) -and ($null -ne $($_.Parent)) }
                    # Increment the indexNumber
                    $indexNumber++
                }             
            }
            else {
                # If there cannot any action found with the previous action's ActionName in the RunAfter property, search for the action has a parent with the false condition.
                if ($Actions | Where-Object { $_.RunAfter -eq $($currentAction.ActionName) }) {
                    $Actions | Where-Object { $_.RunAfter -eq $($currentAction.ActionName) } | 
                    Add-Member -MemberType NoteProperty -Name Order -Value $indexNumber 
                    # CurrentAction will be empty if the ??
                    $currentAction = ($Actions | Where-Object { $_.RunAfter -eq $($currentAction.ActionName) })
                    # Increment the indexNumber
                    $indexNumber++                    
                }
                elseif ($Actions | Where-Object { $_.RunAfter -eq $(('{0}-False') -f $(($currentAction.Parent).Substring(0, ($currentAction.Parent).length - 5))) } ) {
                    $Actions | Where-Object { $_.RunAfter -eq $(('{0}-False') -f $(($currentAction.Parent).Substring(0, ($currentAction.Parent).length - 5))) }  |
                    Add-Member -MemberType NoteProperty -Name Order -Value $indexNumber 
                    $currentAction = $Actions | Where-Object { $_.RunAfter -eq $(('{0}-False') -f $(($currentAction.Parent).Substring(0, ($currentAction.Parent).length - 5))) }
                    # Increment the indexNumber
                    $indexNumber++
                }
                else {
                    # If there cannot any action found with the previous action's ActionName in the RunAfter property, search for the action has a parent with the same name as the currents action's runasfter property.
                    if ($Actions | Where-Object { $_.RunAfter -eq $($currentAction.Parent) -and !($_ | Get-Member -MemberType NoteProperty 'Order') }) {
                        $Actions | Where-Object { $_.RunAfter -eq $($currentAction.Parent) -and !($_ | Get-Member -MemberType NoteProperty 'Order') } | 
                        Add-Member -MemberType NoteProperty -Name Order -Value $indexNumber 
                        # CurrentAction will be empty if the ??
                        $currentAction = ($Actions | Where-Object { ($_ | Get-Member -MemberType NoteProperty 'Order') -and ($_.Order -eq $indexNumber) })
                        # Increment the indexNumber
                        $indexNumber++                    
                    }
                }                         
            }                
        }
        Write-Verbose -Message ('Current action {0} with Order Id {1}' -f $($currentAction.ActionName), $($currentAction.Order) )
    }
}

Function Format-MarkdownTableJson {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $Json
    )

    (($Json -replace '^{', '<pre>{') -replace '}$', '}</pre>') -replace '\r\n', '<br>'
}

# From PowerShell module AzViz. (https://raw.githubusercontent.com/PrateekKumarSingh/AzViz/master/AzViz/src/private/Test-AzLogin.ps1)
Function Test-AzLogin {
    [CmdletBinding()]
    [OutputType([boolean])]
    [Alias()]
    Param()

    Begin {
    }
    Process {
        # Verify we are signed into an Azure account
        try {
            try {
                Import-Module Az.Accounts -Verbose:$false   
            }
            catch {}
            Write-Verbose 'Testing Azure login'
            $isLoggedIn = [bool](Get-AzContext -ErrorAction Stop)
            if (!$isLoggedIn) {                
                Write-Verbose 'Not logged into Azure. Initiate login now.'
                Write-Host 'Enter your credentials in the pop-up window' -ForegroundColor Yellow
                $isLoggedIn = Connect-AzAccount
            }
        }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Write-Verbose 'Not logged into Azure. Initiate login now.'
            Write-Host 'Enter your credentials in the pop-up window' -ForegroundColor Yellow
            $isLoggedIn = Connect-AzAccount
        }
        catch {
            Throw $_.Exception.Message
        }
        [bool]$isLoggedIn
    }
    End {
        
    }
}
#endregion

#region Get Logic App Workflow code
if (!($FilePath)) {

    # Test if the user is logged in
    if (!(Test-AzLogin)) {
        break
    }

    $SubscriptionName = (Get-AzContext).Subscription.Name    

    Write-Host ('Getting Logic App Workflow code for Logic App "{0}" in Resource Group "{1}" and Subscription "{2}"' -f $LogicAppName, $ResourceGroupName, $(Get-AzContext).Subscription.Name) -ForegroundColor Green

    $accessToken = Get-AzAccessToken -ResourceUrl 'https://management.core.windows.net/'
    $headers = @{
        'authorization' = "Bearer $($AccessToken.token)"
    }

    $apiVersion = "2016-06-01"
    $uri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($resourceGroupName)/providers/Microsoft.Logic/workflows/$($logicAppName)?api-version=$($apiVersion)"
    $LogicApp = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
    #endregion

    $Location = $LogicApp.location

    $Objects = Get-Action -Actions $($LogicApp.properties.definition.actions)

    # Get Logic App Connections
    $Connections = Get-Connection -Connection $($LogicApp.properties.parameters.'$connections'.value)
}
else {
    Write-Output -InputObject ('Using Logic App Workflow code from file "{0}"' -f $FilePath)
    $LogicApp = Get-Content -Path $FilePath | ConvertFrom-Json

    $Objects = Get-Action -Actions $($LogicApp.definition.actions)

    # Get Logic App Connections
    # For PowerApps Flows the connections are stored in a connectionMap json file. Skipp for now.
    if ($LogicApp | Get-Member -MemberType NoteProperty -Name 'parameters') {
        $Connections = Get-Connection -Connection $($LogicApp.parameters.'$connections'.value)
    }
    else {
        $Connections = $null
    }
}

if ($VerbosePreference -eq 'Continue') {
    Write-Verbose -Message ('Found {0} actions in Logic App' -f $Objects.Count)
    Write-Verbose ($objects | Format-Table | out-string)
}

# Create the Mermaid code
Write-Host ('Creating Mermaid Diagram for Logic App') -ForegroundColor Green

$mermaidCode = "graph TB" + [Environment]::NewLine
$mermaidCode += "    Trigger" + [Environment]::NewLine


# Group actions by parent property
$objects | Group-Object -Property Parent | ForEach-Object {
    if (![string]::IsNullOrEmpty($_.Name)) {
        $subgraphName = $_.Name
        $mermaidCode += "    subgraph $subgraphName" + [Environment]::NewLine
        $mermaidCode += "    direction TB" + [Environment]::NewLine
        # Add children action nodes to subgraph
        foreach ($childAction in $_.Group.ActionName) {
            $mermaidCode += "        $childAction" + [Environment]::NewLine
        }
        $mermaidCode += "    end" + [Environment]::NewLine
    }
    else {}        
}

# Create links between runafter and actionname properties
foreach ($object in $objects) {
    if ($object | Get-Member -MemberType NoteProperty -Name 'RunAfter') {
        # Check if the runafter property is not empty
        if (![string]::IsNullOrEmpty($object.RunAfter)) {
            $mermaidCode += "    $($object.RunAfter) --> $($object.ActionName)" + [Environment]::NewLine
        }
    }        
}

# Create link between trigger and first action
$firstActionLink = ($objects | Where-Object { $_.Runafter -eq $null }).ActionName
$mermaidCode += "    Trigger --> $firstActionLink" + [Environment]::NewLine

Sort-Action -Actions $objects

if ($VerbosePreference -eq 'Continue') {
    Write-Verbose -Message ('Found {0} actions in Logic App' -f $Objects.Count)
    Write-Verbose ($objects | Select-Object -Property ActionName, RunAfter, Type, Parent, Order | Sort-Object -Property Order | Format-Table | Out-String)
}

#region Generate Markdown documentation for Logic App Workflow
$InputObject = [pscustomobject]@{
    'LogicApp'    = [PSCustomObject]@{
        Name              = $LogicAppName
        ResourceGroupName = $resourceGroupName
        Location          = $Location
        SubscriptionName  = $SubscriptionName

    }
    'Actions'     = $objects
    'Connections' = $Connections
    'Diagram'     = $mermaidCode
}

$options = New-PSDocumentOption -Option @{ 'Markdown.UseEdgePipes' = 'Always'; 'Markdown.ColumnPadding' = 'Single' };
$null = [PSDocs.Configuration.PSDocumentOption]$Options
$markDownFile = Invoke-PSDocument -Path $templatePath -Name $templateName -InputObject $InputObject -Culture 'en-us' -Option $options -OutputPath $OutputPath
Write-Host ('Logic App Workflow Markdown document is being created at {0}' -f $($markDownFile.FullName)) -ForegroundColor Green
#endregion