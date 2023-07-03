Document 'Azure-LogicApp-Documentation' {

    # Helper function
    Function Format-MarkdownTableJson {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $true)]
            $Json
        )
    
        (($Json -replace '^{', '<pre>{') -replace '}$', '}</pre>') -replace '\r\n', '<br>'
    }    

    "# Azure Logic App Documentation - $($InputObject.LogicApp.name)"

    Section 'Introduction' {
        "This document describes the Azure Logic App Workflow **$($InputObject.LogicApp.name)** in the **$($InputObject.LogicApp.ResourceGroupName)** resource group in the **$($InputObject.LogicApp.SubscriptionName)** subscription."
        "This document is programmatically generated using a PowerShell script."

        "Date: $(Get-Date -Format 'yyyy-MM-dd')"
    }

    Section 'Logic App Workflow Actions'{
@"        
```````mermaid
$($InputObject.diagram)
```````
"@       
}

    Section 'Logic App Workflow Actions' {
        "This section shows an overview of Logic App Workflow actions and their dependencies."

        Section 'Actions' {            
            $($InputObject.actions) |                 
            Sort-Object -Property Order |  
                Select-Object -Property 'ActionName', 'Type', 'RunAfter', @{Name='Inputs';Expression={Format-MarkdownTableJson -Json $($_.Inputs | ConvertFrom-Json | ConvertTo-Json)  }} |
                Table -Property 'ActionName', 'Type', 'RunAfter', 'Inputs'
        }
    }
}