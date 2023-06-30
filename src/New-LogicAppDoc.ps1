[CmdLetBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$LogicAppName,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

Set-StrictMode -Version 3.0

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
        $actionName = $key.Replace(' ', '_').Replace('(', '').Replace(')', '')

        # new runafter code
        $runAfter = if (![string]::IsNullOrWhitespace($action.runafter)) {
            $action.runAfter.PSObject.Properties.Name.Replace(' ', '_').Replace('(', '').Replace(')', '')
        }
        elseif (([string]::IsNullOrWhitespace($action.runafter)) -and $Parent) {
            # if Runafter is empty but has parent use parent.
            $Parent -replace '(-False|-True)', ''
        }
        else {
            # if Runafter is empty and has no parent use null.
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

Function New-ActionOrder {
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
    for ($i = 0; $i -lt $Actions.Count; $i++) {
        # Search for the action that has the first action's ActionName in the RunAfter property or the previous action's ActionName
        if (![string]::IsNullOrEmpty($firstAction)) {
            $Actions | Where-Object { $_.RunAfter -eq $firstAction.ActionName } | 
            Add-Member -MemberType NoteProperty -Name Order -Value $indexNumber -PassThru
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
                    $_.RunAfter = $_.Parent 
                    # $_ |
                    #     Add-Member -MemberType NoteProperty -Name Order -Value $indexNumber -PassThru
                    # $currentActionName = ($Actions | Where-Object { $_.RunAfter -eq $currentActionName }).ActionName
                    # # Increment the indexNumber
                    # $indexNumber++
                }
                # Iterate first the condition status true actions.
                $Actions | Where-Object { $_.RunAfter -eq $(('{0}-True') -f $($currentAction.ActionName))}  |
                    Add-Member -MemberType NoteProperty -Name Order -Value $indexNumber 
                $currentAction = $Actions | Where-Object { $_.RunAfter -eq $(('{0}-True') -f $($currentAction.ActionName))} 
                # Increment the indexNumber
                $indexNumber++
            }
            else {
                # If there cannot any action found with the previous action's ActionName in the RunAfter property, search for the action has a parent with the false condition.
                if ($Actions | Where-Object { $_.RunAfter -eq $($currentAction.ActionName) }) {
                    $Actions | Where-Object { $_.RunAfter -eq $($currentAction.ActionName) } | 
                        Add-Member -MemberType NoteProperty -Name Order -Value $indexNumber 
                    $currentAction = ($Actions | Where-Object { $_.RunAfter -eq $($currentAction.ActionName) })
                    # Increment the indexNumber
                    $indexNumber++                    
                }
                else {
                    $Actions | Where-Object { $_.RunAfter -eq $(('{0}-False') -f $(($currentAction.Parent).Substring(0,($currentAction.Parent).length-5)))}  |
                        Add-Member -MemberType NoteProperty -Name Order -Value $indexNumber 
                    $currentAction = $Actions | Where-Object { $_.RunAfter -eq $(('{0}-False') -f $(($currentAction.Parent).Substring(0,($currentAction.Parent).length-5)))}
                    # Increment the indexNumber
                    $indexNumber++
                }
                
            }                
        }
    }

}
#endregion

#region Get Logic App Workflow code
$accessToken = Get-AzAccessToken -ResourceUrl 'https://management.core.windows.net/'
$headers = @{
    'authorization' = "Bearer $($AccessToken.token)"
}

$apiVersion = "2016-06-01"
$uri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($resourceGroupName)/providers/Microsoft.Logic/workflows/$($logicAppName)?api-version=$($apiVersion)"
$LogicApp = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
#endregion

Get-Action -Actions $($LogicApp.properties.definition.actions) -OutVariable objects

New-ActionOrder -Actions $objects

# Create the Mermaid code
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
        #$mermaidCode += [Environment]::NewLine
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
$firstAction = ($objects | Where-Object { $_.Runafter -eq $null }).ActionName
$mermaidCode += "    Trigger --> $firstAction" + [Environment]::NewLine

#region Generate Markdown documentation for Logic App Workflow
Write-Output -InputObject 'Logic App Workflow Markdown document is being created'
$InputObject = [pscustomobject]@{
    'LogicApp' = [PSCustomObject]@{
        Name              = $LogicApp.name
        ResourceGroupName = $resourceGroupName
        Location          = $LogicApp.location
        SubscriptionName  = (Get-AzContext).Subscription.Name

    }
    'Actions'  = $objects
    'Diagram'  = $mermaidCode

}

$options = New-PSDocumentOption -Option @{ 'Markdown.UseEdgePipes' = 'Always'; 'Markdown.ColumnPadding' = 'Single' };
$null = [PSDocs.Configuration.PSDocumentOption]$Options
Invoke-PSDocument -Path $templatePath -Name $templateName -InputObject $InputObject -Culture 'en-us' -Option $options -OutputPath $OutputPath
#endregion