Document 'PowerAutomate-Documentation' {

    # Helper function
    Function Format-MarkdownTableJson {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $true)]
            $Json
        )
    
        (($Json -replace '^{', '<pre>{') -replace '}$', '}</pre>') -replace '\r\n', '<br>'
    }    

    "# PowerAutomate Flow Documentation - $($InputObject.PowerAutomateFlow.name)"

    Section 'Introduction' {
        "This document describes the PowerAutomate Flow **$($InputObject.PowerAutomateFlow.name)** in the **$($InputObject.PowerAutomateFlow.EnvironmentName)** Environment."
        "This document is programmatically generated using a PowerShell script."
        
        "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }
   
    Section 'PowerAutomate Flow Diagram' {
        @"        
``````mermaid
$($InputObject.diagram)
``````
"@       
    }
 
        Section 'PowerAutomate Flow Actions' {
        "This section shows an overview of PowerAutomate Flow actions and their dependencies."

        Section 'PowerAutomate Flow Triggers' {
            $($InputObject.Triggers) | 
            Select-Object -Property 'Name', @{Name = 'Type'; Expression = { $_.Value.type } }, @{Name = 'Inputs'; Expression = { Format-MarkdownTableJson -Json $($_.value.Inputs | ConvertTo-Json -Depth 10) } } |
            Table -Property 'Name', 'Type', 'Inputs'
        }

        Section 'Actions' {            
            $($InputObject.actions) |                 
            Sort-Object -Property Order |  
            Select-Object -Property 'ActionName', 'Type', 'RunAfter', @{Name = 'Inputs'; Expression = { Format-MarkdownTableJson -Json $($_.Inputs | ConvertTo-Json -Depth 10) } } |
            Table -Property 'ActionName', 'Type', 'RunAfter', 'Inputs'
        }
    }

    Section 'PowerAutomate Flow Connections' {
        "This section shows an overview of PowerAutomate Flow connections."

        Section 'Connections' {
            $($InputObject.Connections) |
            Select-Object -Property 'ConnectionName', @{Name = 'ConnectionId'; Expression = {$_.id}} |
            Table -Property 'ConnectionName', 'ConnectionId'
        }
    }
}