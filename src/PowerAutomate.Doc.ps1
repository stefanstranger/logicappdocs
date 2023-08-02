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
```````mermaid
$($InputObject.diagram)
```````
"@       
    }
    
        Section 'PowerAutomate Flow Actions' {
        "This section shows an overview of PowerAutomate Flow actions and their dependencies."

        Section 'Actions' {            
            $($InputObject.actions) |                 
            Sort-Object -Property Order |  
            Select-Object -Property 'ActionName', 'Type', 'RunAfter', @{Name = 'Inputs'; Expression = { Format-MarkdownTableJson -Json $($_.Inputs | ConvertFrom-Json | ConvertTo-Json -Depth 10) } } |
            Table -Property 'ActionName', 'Type', 'RunAfter', 'Inputs'
        }
    }

    Section 'PowerAutomate Flow Connections' {
        "This section shows an overview of PowerAutomate Flow connections."

        Section 'Connections' {
            $($InputObject.Connections) |
            Select-Object -Property 'ConnectionName', 'ConnectionId', @{Name = 'ConnectionProperties'; Expression = { Format-MarkdownTableJson -Json $($_.ConnectionProperties | ConvertTo-Json) } } |
            Table -Property 'ConnectionName', 'ConnectionId', 'ConnectionProperties'
        }
    }

}