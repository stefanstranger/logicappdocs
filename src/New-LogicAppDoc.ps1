[CmdLetBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$LogicAppName
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
        <#
        $runAfter = if ($action.runAfter.PSObject.Properties.Name) {
            $action.runAfter.PSObject.Properties.Name.Replace(' ', '_').Replace('(', '').Replace(')', '')
        }
        elseif (!($action.runAfter.PSObject.Properties.Name) -and $Parent) {
            # if Runafter is empty but has parent use parent.
            $Parent -replace '(-False|-True)', ''
        }
        else {
            # if Runafter is empty and has no parent use null.
            $null
        }
        #>

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

        # Create childActions 
        #$childActions = if ($action.Actions) { $action.Actions.PSObject.Properties.Name } else { $null }

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
        $mermaidCode += [Environment]::NewLine
    }
    else {}        
}

# Create links between runafter and actionname properties
foreach ($object in $objects) {
    if ($object | Get-Member -MemberType NoteProperty -Name 'RunAfter') {
        # Check if the runafter property is not empty
        if (![string]::IsNullOrEmpty($object.RunAfter)) {
            $mermaidCode += "    $($object.RunAfter) --> $($object.ActionName)" + [Environment]::NewLine}
        }        
}

# Create link between trigger and first action
$firstAction = ($objects | Where-Object { $_.Runafter -eq $null }).ActionName
$mermaidCode += "    Trigger --> $firstAction" + [Environment]::NewLine

$mermaidCode

