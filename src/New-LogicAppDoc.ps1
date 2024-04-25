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
    [string]$OutputPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [boolean]$ConvertToADOMarkdown = $false,

    [Parameter(Mandatory = $false)]
    [bool]$Show = $false
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'


@"
██╗      ██████╗  ██████╗ ██╗ ██████╗ █████╗ ██████╗ ██████╗ ██████╗  ██████╗  ██████╗███████╗
██║     ██╔═══██╗██╔════╝ ██║██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔════╝
██║     ██║   ██║██║  ███╗██║██║     ███████║██████╔╝██████╔╝██║  ██║██║   ██║██║     ███████╗
██║     ██║   ██║██║   ██║██║██║     ██╔══██║██╔═══╝ ██╔═══╝ ██║  ██║██║   ██║██║     ╚════██║
███████╗╚██████╔╝╚██████╔╝██║╚██████╗██║  ██║██║     ██║     ██████╔╝╚██████╔╝╚██████╗███████║
╚══════╝ ╚═════╝  ╚═════╝ ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚═════╝  ╚═════╝  ╚═════╝╚══════╝
                                                                                                                                                         
Author: Stefan Stranger
Github: https://github.com/stefanstranger/logicappdocs
Version: 1.1.6

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

#region dot source Helper Functions
. (Join-Path $PSScriptRoot 'Helper.ps1')
#endregion

#region Set Variables
$templateName = 'Azure-LogicApp-Documentation'
$templatePath = (Join-Path $PSScriptRoot 'LogicApp.Doc.ps1')
#endregion

#region Helper Functions

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
    if ($LogicApp.properties.parameters | Get-Member -MemberType NoteProperty -Name '$connections') {
        $Connections = Get-Connection -Connection $($LogicApp.properties.parameters.'$connections'.value)
    }
    else {
        $Connections = $null
    }
}
else {
    Write-Output -InputObject ('Using Logic App Workflow code from file "{0}"' -f $FilePath)
    $LogicApp = Get-Content -Path $FilePath | ConvertFrom-Json

    $Objects = Get-Action -Actions $($LogicApp.definition.actions)

    # Get Logic App Connections
    if ($LogicApp | Get-Member -MemberType NoteProperty -Name 'parameters') {
        if ($LogicApp.parameters | Get-Member -MemberType NoteProperty -Name '$connections') {
            $Connections = Get-Connection -Connection $($LogicApp.parameters.'$connections'.value)
        }
        else {
            $Connections = $null
        }
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
$mermaidCode += "    $($triggers.name -replace '[|(|)|@]', '_')" + [Environment]::NewLine


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
            if (($object.runAfter | Measure-Object).count -eq 1) {
                $mermaidCode += "    $($object.RunAfter) --> $($object.ActionName)" + [Environment]::NewLine
            }
            else {
                foreach ($runAfter in $object.RunAfter) {
                    $mermaidCode += "    $runAfter --> $($object.ActionName)" + [Environment]::NewLine
                }
            }
        }
    }        
}

# Create link between trigger and first action
$firstActionLink = ($objects | Where-Object { $_.Runafter -eq $null }).ActionName
$mermaidCode += "    $($triggers.name -replace '[|(|)|@]', '_') --> $firstActionLink" + [Environment]::NewLine


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
$invokePSDocumentSplat = @{
    Path         = $templatePath
    Name         = $templateName
    InputObject  = $InputObject
    Culture      = 'en-us'
    Option       = $options
    OutputPath   = $OutputPath
    InstanceName = $LogicAppName
}
$markDownFile = Invoke-PSDocument @invokePSDocumentSplat
$outputFile = $($markDownFile.FullName)
# If file contains space remove the spaces and rename file
if ($outputFile -match '\s') {
    $newOutputFile = $outputFile -replace '\s', '_'
    if (Test-Path -Path $newOutputFile) {
        Remove-Item -Path $newOutputFile -Force
    }
    Rename-Item -Path $outputFile -NewName $newOutputFile -Force
    $outputFile = $newOutputFile
}
Write-Host ('LogicApp Flow Markdown document is being created at {0}' -f $outputFile) -ForegroundColor Green
#endregion

#region Convert Markdown to ADOMarkdown if ConvertTo-ADOMarkdown parameter is used
if ($ConvertToADOMarkdown) {
    # Run Bootstrap.ps1 to install mermaid-cli
    . (Join-Path $PSScriptRoot 'Bootstrap.ps1')
    Write-Host ('Converting Markdown to ADOMarkdown') -ForegroundColor Green
    $converttedOutputFile = ($outputFile -replace '.md$', '-ado.md')
    & {mmdc -i $outputFile  -o $converttedOutputFile -e png}
    Write-Host ('ADOMarkdown document is being created at {0}' -f $converttedOutputFile) -ForegroundColor Green
}

#region Open Markdown document if show parameter is used
if ($Show) {
    Write-Host ('Opening Markdown document in default Markdown viewer') -ForegroundColor Green
    if ($ConvertToADOMarkdown) {
        Start-Process -FilePath $converttedOutputFile
    }
    else {
        Start-Process -FilePath $outputFile
    }
}
#endregion