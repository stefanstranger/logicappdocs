# Azure Logic App Documentation - logic-jiraintegration-demo

## Introduction

This document describes the Azure Logic App Workflow **logic-jiraintegration-demo** in the **jiraintegration-demo-rg** resource group in the **Visual Studio Enterprise** subscription.

This document is programmatically generated using a PowerShell script.

Date: 2023-07-10 16:37:29

## Logic App Workflow Diagram

```mermaid
graph TB
    Trigger
    subgraph Condition_-_Status-False
    direction TB
        Compose_-_Resolved_-_Current_Item
        For_Each_-_JIRA_SHA_Incident
        HTTP_-_Get_all_Active_JIRA_SHA_Incidents
        Parse_JSON_-_HTTP_-_Get_all_Active_JIRA_SHA_Incidents
    end
    subgraph Condition_-_Status-True
    direction TB
        Compose_-_Current_Item
        Compose_-_SHA_TimeGeneratedUTC
        Compose_-_Subscriptions_Array
        Create_a_new_issue_V2
        Html_to_text_-_Summary_Communication
    end
    subgraph Condition-True
    direction TB
        HTTP_-_Close_JIRA_SHA_Incident
    end
    subgraph For_Each_-_JIRA_SHA_Incident
    direction TB
        Compose_-_Current_JIRA_SHA_Incident
        Compose_-_JIRA_Incident_Id
        Compose_-_TICKET_ID_Number
        Condition
    end
    subgraph For_Each_-_SHA
    direction TB
        Condition_-_Status
    end
    Parse_JSON_-_Log_Analytics_Search_Query --> For_Each_-_SHA
    For_Each_-_SHA --> Condition_-_Status
    Compose_-_SHA_TimeGeneratedUTC --> Compose_-_Current_Item
    Condition_-_Status --> Compose_-_SHA_TimeGeneratedUTC
    Compose_-_Current_Item --> Compose_-_Subscriptions_Array
    Html_to_text_-_Summary_Communication --> Create_a_new_issue_V2
    Compose_-_Subscriptions_Array --> Html_to_text_-_Summary_Communication
    Condition_-_Status --> Compose_-_Resolved_-_Current_Item
    Parse_JSON_-_HTTP_-_Get_all_Active_JIRA_SHA_Incidents --> For_Each_-_JIRA_SHA_Incident
    For_Each_-_JIRA_SHA_Incident --> Compose_-_Current_JIRA_SHA_Incident
    Compose_-_TICKET_ID_Number --> Compose_-_JIRA_Incident_Id
    Compose_-_Current_JIRA_SHA_Incident --> Compose_-_TICKET_ID_Number
    Compose_-_JIRA_Incident_Id --> Condition
    Condition --> HTTP_-_Close_JIRA_SHA_Incident
    Compose_-_Resolved_-_Current_Item --> HTTP_-_Get_all_Active_JIRA_SHA_Incidents
    HTTP_-_Get_all_Active_JIRA_SHA_Incidents --> Parse_JSON_-_HTTP_-_Get_all_Active_JIRA_SHA_Incidents
    Run_query_and_list_results --> Parse_JSON_-_Log_Analytics_Search_Query
    Parse_JSON --> Run_query_and_list_results
    Trigger --> Parse_JSON

```

## Logic App Workflow Actions

This section shows an overview of Logic App Workflow actions and their dependencies.

### Actions

| ActionName | Type | RunAfter | Inputs |
| ---------- | ---- | -------- | ------ |
| Parse_JSON | ParseJson |  | <pre>{<br>  "content": "@triggerBody()",<br>  "schema": {<br>    "properties": {<br>      "data": "@{properties=; type=object}",<br>      "schemaId": "@{type=string}"<br>    },<br>    "type": "object"<br>  }<br>}</pre> |
| Run_query_and_list_results | ApiConnection | Parse_JSON | <pre>{<br>  "body": "@{body('Parse_JSON')['data']['alertContext']['Condition']['allOf'][0]['searchQuery']}",<br>  "host": {<br>    "connection": {<br>      "name": "@parameters('$connections')['azuremonitorlogs']['connectionId']"<br>    }<br>  },<br>  "method": "post",<br>  "path": "/queryData",<br>  "queries": {<br>    "resourcegroups": "la-demo-rg",<br>    "resourcename": "la-demo-workspace",<br>    "resourcetype": "Log Analytics Workspace",<br>    "subscriptions": "fbca04ea-152b-415f-82a4-ae1ffc5f4267",<br>    "timerange": "Last hour"<br>  }<br>}</pre> |
| Parse_JSON_-_Log_Analytics_Search_Query | ParseJson | Run_query_and_list_results | <pre>{<br>  "content": "@body('Run_query_and_list_results')",<br>  "schema": {<br>    "properties": {<br>      "AZURE_SERVICE": "@{type=string}",<br>      "IMPACT": "@{type=string}",<br>      "JIRA_ASSIGNMENT_GROUP": "@{type=string}",<br>      "JIRA_COMPONENT_NAME": "@{type=string}",<br>      "SUMMARY_Communication": "@{type=string}",<br>      "SUMMARY_Title": "@{type=string}",<br>      "Status": "@{type=string}",<br>      "Subscriptions": "@{type=string}",<br>      "TICKET_ID_Number": "@{type=string}",<br>      "TimeGenerated": "@{type=string}"<br>    },<br>    "type": "object"<br>  }<br>}</pre> |
| For_Each_-_SHA | Foreach | Parse_JSON_-_Log_Analytics_Search_Query | null |
| Condition_-_Status | If | For_Each_-_SHA | null |
| Compose_-_SHA_TimeGeneratedUTC | Compose | Condition_-_Status-True | "@items('For Each - SHA')?['TimeGeneratedUTC']" |
| Compose_-_Current_Item | Compose | Compose_-_SHA_TimeGeneratedUTC | "@items('For Each - SHA')" |
| Compose_-_Subscriptions_Array | Compose | Compose_-_Current_Item | "@array(items('For Each - SHA').Subscriptions)" |
| Html_to_text_-_Summary_Communication | ApiConnection | Compose_-_Subscriptions_Array | <pre>{<br>  "body": "<p>@{items('For Each - SHA')?['SUMMARY_Communication']}</p>",<br>  "host": {<br>    "connection": {<br>      "name": "@parameters('$connections')['conversionservice']['connectionId']"<br>    }<br>  },<br>  "method": "post",<br>  "path": "/html2text"<br>}</pre> |
| Create_a_new_issue_V2 | ApiConnection | Html_to_text_-_Summary_Communication | <pre>{<br>  "body": {<br>    "fields": {<br>      "customfield_10041": "Azure",<br>      "customfield_10065": "@items('For Each - SHA')?['JIRA_ASSIGNMENT_GROUP']",<br>      "description": "Azure Service Health Issue\n\nStatus: @{items('For Each - SHA')?['Status']} \nStart Time: @{items('For Each - SHA')?['TimeGeneratedUTC']}\nSummary of Impact: @{body('Html to text - Summary Communication')}\nTracking ID: @{items('For Each - SHA')?['TICKET_ID_Number']}\nImpacted Services: @{items('For Each - SHA')?['AZURE_SERVICE']}\nImpacted Subscriptions: @{items('For Each - SHA')?['Subscriptions']}",<br>      "summary": "@{items('For Each - SHA')?['SUMMARY_Title']} - @{items('For Each - SHA')?['TICKET_ID_Number']}"<br>    }<br>  },<br>  "host": {<br>    "connection": {<br>      "name": "@parameters('$connections')['jira']['connectionId']"<br>    }<br>  },<br>  "method": "post",<br>  "path": "/v2/issue",<br>  "queries": {<br>    "issueTypeIds": "10005",<br>    "projectKey": "IP"<br>  }<br>}</pre> |
| Compose_-_Resolved_-_Current_Item | Compose | Condition_-_Status-False | "@items('For Each - SHA')" |
| HTTP_-_Get_all_Active_JIRA_SHA_Incidents | Http | Compose_-_Resolved_-_Current_Item | <pre>{<br>  "headers": {<br>    "Authorization": "Basic ******"<br>  },<br>  "method": "GET",<br>  "uri": "https://contoso.atlassian.net/rest/api/3/search?jql=Status!=Completed%20and%20cf[10041]~\"Azure\"&fields=key,summary,status,resolution,customfield_10041,description"<br>}</pre> |
| Parse_JSON_-_HTTP_-_Get_all_Active_JIRA_SHA_Incidents | ParseJson | HTTP_-_Get_all_Active_JIRA_SHA_Incidents | <pre>{<br>  "content": "@body('HTTP_-_Get_all_Active_JIRA_SHA_Incidents')",<br>  "schema": {<br>    "properties": {<br>      "expand": "@{type=string}",<br>      "issues": "@{items=; type=array}",<br>      "maxResults": "@{type=integer}",<br>      "startAt": "@{type=integer}",<br>      "total": "@{type=integer}"<br>    },<br>    "type": "object"<br>  }<br>}</pre> |
| For_Each_-_JIRA_SHA_Incident | Foreach | Parse_JSON_-_HTTP_-_Get_all_Active_JIRA_SHA_Incidents | null |
| Compose_-_Current_JIRA_SHA_Incident | Compose | For_Each_-_JIRA_SHA_Incident | "@items('For_Each_-_JIRA_SHA_Incident')" |
| Compose_-_TICKET_ID_Number | Compose | Compose_-_Current_JIRA_SHA_Incident | "@items('For Each - SHA')?['TICKET_ID_Number']" |
| Compose_-_JIRA_Incident_Id | Compose | Compose_-_TICKET_ID_Number | "@items('For_Each_-_JIRA_SHA_Incident')['id']" |
| Condition | If | Compose_-_JIRA_Incident_Id | null |
| HTTP_-_Close_JIRA_SHA_Incident | Http | Condition | <pre>{<br>  "body": {<br>    "transition": {<br>      "id": "111"<br>    },<br>    "update": {<br>      "comment": ""<br>    }<br>  },<br>  "headers": {<br>    "Authorization": "Basic ******"<br>  },<br>  "method": "POST",<br>  "uri": "https://contoso.atlassian.net/rest/api/3/issue/@{outputs('Compose_-_JIRA_Incident_Id')}/transitions"<br>}</pre> |

## Logic App Connections

This section shows an overview of Logic App Workflow connections.

### Connections

| ConnectionName | ConnectionId | ConnectionProperties |
| -------------- | ------------ | -------------------- |
| azuremonitorlogs | /subscriptions/fbca04ea-152b-415f-82a4-ae1ffc5f4267/resourceGroups/jiraintegration-demo-rg/providers/Microsoft.Web/connections/azuremonitorlogs | null |
| conversionservice | /subscriptions/fbca04ea-152b-415f-82a4-ae1ffc5f4267/resourceGroups/jiraintegration-demo-rg/providers/Microsoft.Web/connections/conversionservice | null |
| jira-3 | /subscriptions/fbca04ea-152b-415f-82a4-ae1ffc5f4267/resourceGroups/jiraintegration-demo-rg/providers/Microsoft.Web/connections/jira-3 | null |
