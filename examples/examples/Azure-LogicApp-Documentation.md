# Azure Logic App Documentation - powerapp-flow-demo

## Introduction

This document describes the Azure Logic App Workflow **powerapp-flow-demo** in the **jiraintegration-demo-rg** resource group in the **Visual Studio Enterprise** subscription.

This document is programmatically generated using a PowerShell script.

Date: 2023-07-19 09:37:39

## Logic App Workflow Diagram

```mermaid
graph TB
    Trigger
    subgraph Apply_to_each
    direction TB
        Get_message_details
        Condition
    end
    subgraph Apply_to_each_-_DutchBirthdays_items
    direction TB
        Compose
        Append_to_string_variable_-_test
    end
    subgraph Condition_-_Check_for_empty_varDutchPeopleBirthdays-False
    direction TB
        Append_to_string_variable_-_varInterestingFact
        Append_to_string_variable_-_varInterestingFact_with_varDutchPeopleBirthdays
    end
    subgraph Condition_-_Check_for_empty_varDutchPeopleBirthdays-True
    direction TB
        Set_variable_-_varInterestingFact
    end
    subgraph Condition-True
    direction TB
        Parse_JSON
        Post_message_in_a_chat_or_channel
        Compose_-_Get_Mention_Id
        Get_an_-at-mention_token_for_a_user
    end
    Compose_-_Get_messageid_property_from_first_Teams_Chat_message --> Apply_to_each
    Apply_to_each --> Get_message_details
    Get_message_details --> Condition
    Condition --> Parse_JSON
    Get_an_-at-mention_token_for_a_user --> Post_message_in_a_chat_or_channel
    Parse_JSON --> Compose_-_Get_Mention_Id
    Compose_-_Get_Mention_Id --> Get_an_-at-mention_token_for_a_user
    Condition_-_Check_for_empty_varDutchPeopleBirthdays --> Compose_-_Get_messageid_property_from_first_Teams_Chat_message
    Initialize_variable_-_varInterestingFact --> Compose_-_Get_random_Giphy_Birtday_url
    Compose_-_Get_random_Giphy_Birtday_url --> Compose_-_Output_Giphy_Birtday_url
    Initialize_variable_-_varBirthdayGifUrls --> Initialize_variable_-_varDutchPeopleBirthdays
    Apply_to_each_-_DutchBirthdays_items --> Condition_-_Check_for_empty_varDutchPeopleBirthdays
    Condition_-_Check_for_empty_varDutchPeopleBirthdays --> Set_variable_-_varInterestingFact
    Condition_-_Check_for_empty_varDutchPeopleBirthdays --> Append_to_string_variable_-_varInterestingFact
    Append_to_string_variable_-_varInterestingFact --> Append_to_string_variable_-_varInterestingFact_with_varDutchPeopleBirthdays
    Initialize_variable_-_varDutchPeopleBirthdays --> Initialize_variable_-_varInterestingFact
    Compose_-_Output_Giphy_Birtday_url --> Compose_-_Get_todays_date
    Compose_-_Get_todays_date --> SharePoint_-_Get_DutchBirthdays_List_Items
    SharePoint_-_Get_DutchBirthdays_List_Items --> Apply_to_each_-_DutchBirthdays_items
    Apply_to_each_-_DutchBirthdays_items --> Compose
    Compose --> Append_to_string_variable_-_test
    Trigger --> Initialize_variable_-_varBirthdayGifUrls

```

## Logic App Workflow Actions

This section shows an overview of Logic App Workflow actions and their dependencies.

### Actions

| ActionName | Type | RunAfter | Inputs |
| ---------- | ---- | -------- | ------ |
| Initialize_variable_-_varBirthdayGifUrls | InitializeVariable |  | <pre>{<br>  "variables": [<br>    {<br>      "name": "varBirthdayGifUrls",<br>      "type": "array",<br>      "value": [<br>        "https://media.giphy.com/media/l4KibWpBGWchSqCRy/giphy.gif",<br>        "https://media.giphy.com/media/WRL7YgP42OKns22wRD/giphy.gif",<br>        "https://media.giphy.com/media/26BRtW4zppWWjrsPu/giphy.gif",<br>        "https://media.giphy.com/media/VX5pqkR3E6EmlKFlmq/giphy.gif",<br>        "https://media.giphy.com/media/eDSnmeQ4MWmB2/giphy.gif",<br>        "https://media.giphy.com/media/Kg2tFStNdUsOmxv2GC/giphy.gif",<br>        "https://media.giphy.com/media/kaBuCyQLuCANfmoFMC/giphy.gif",<br>        "https://media.giphy.com/media/Dn5nT3gtXXqiRysvK2/giphy.gif"<br>      ]<br>    }<br>  ]<br>}</pre> |
| Initialize_variable_-_varDutchPeopleBirthdays | InitializeVariable | Initialize_variable_-_varBirthdayGifUrls | <pre>{<br>  "variables": [<br>    {<br>      "name": "varDutchPeopleBirthdays",<br>      "type": "string"<br>    }<br>  ]<br>}</pre> |
| Initialize_variable_-_varInterestingFact | InitializeVariable | Initialize_variable_-_varDutchPeopleBirthdays | <pre>{<br>  "variables": [<br>    {<br>      "name": "varInterestingFact",<br>      "type": "string"<br>    }<br>  ]<br>}</pre> |
| Compose_-_Get_random_Giphy_Birtday_url | Compose | Initialize_variable_-_varInterestingFact | "@variables('varBirthdayGifUrls')?[rand(0,length(variables('varBirthdayGifUrls')))]" |
| Compose_-_Output_Giphy_Birtday_url | Compose | Compose_-_Get_random_Giphy_Birtday_url | "@outputs('Compose_-_Get_random_Giphy_Birtday_url')" |
| Compose_-_Get_todays_date | Compose | Compose_-_Output_Giphy_Birtday_url | "@formatDateTime(utcNow(), 'M/d')" |
| SharePoint_-_Get_DutchBirthdays_List_Items | OpenApiConnection | Compose_-_Get_todays_date | <pre>{<br>  "host": {<br>    "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",<br>    "connectionName": "shared_sharepointonline",<br>    "operationId": "GetItems"<br>  },<br>  "parameters": {<br>    "dataset": "https://microsofteur-my.sharepoint.com/personal/stefstr_microsoft_com",<br>    "table": "d6f0b0db-cd01-4b99-b0b6-518872eb17a6",<br>    "$filter": "Title eq '@{outputs('Compose_-_Get_todays_date')}'"<br>  },<br>  "authentication": "@parameters('$authentication')"<br>}</pre> |
| Apply_to_each_-_DutchBirthdays_items | Foreach | SharePoint_-_Get_DutchBirthdays_List_Items | null |
| Compose | Compose | Apply_to_each_-_DutchBirthdays_items | "@items('Apply_to_each_-_DutchBirthdays_items')?['field_2']" |
| Append_to_string_variable_-_test | AppendToStringVariable | Compose | <pre>{<br>  "name": "varDutchPeopleBirthdays",<br>  "value": "@concat('<li>',outputs('Compose'),decodeUriComponent('%0A'),'</li>')"<br>}</pre> |
| Condition_-_Check_for_empty_varDutchPeopleBirthdays | If | Apply_to_each_-_DutchBirthdays_items | null |
| Set_variable_-_varInterestingFact | SetVariable | Condition_-_Check_for_empty_varDutchPeopleBirthdays-True | <pre>{<br>  "name": "varInterestingFact",<br>  "value": "<p>You are quite unique, no Dutch people are born on @{utcNow('MM/dd')}</p>"<br>}</pre> |
| Append_to_string_variable_-_varInterestingFact | AppendToStringVariable | Condition_-_Check_for_empty_varDutchPeopleBirthdays-False | <pre>{<br>  "name": "varInterestingFact",<br>  "value": "<p>Did you know, that the following people are also celebrating their birthdays on exact this date,</p>"<br>}</pre> |
| Append_to_string_variable_-_varInterestingFact_with_varDutchPeopleBirthdays | AppendToStringVariable | Append_to_string_variable_-_varInterestingFact | <pre>{<br>  "name": "varInterestingFact",<br>  "value": "@variables('varDutchPeopleBirthdays')"<br>}</pre> |
| Get_an_-at-mention_token_for_a_user | OpenApiConnection | Compose_-_Get_Mention_Id | <pre>{<br>  "host": {<br>    "apiId": "/providers/Microsoft.PowerApps/apis/shared_teams",<br>    "connectionName": "shared_teams",<br>    "operationId": "AtMentionUser"<br>  },<br>  "parameters": {<br>    "userId": "@outputs('Compose_-_Get_Mention_Id')"<br>  },<br>  "authentication": "@parameters('$authentication')"<br>}</pre> |
| Compose_-_Get_Mention_Id | Compose | Parse_JSON | "@first(body('Parse_JSON')?['mentions'])?['mentioned']?['user'].id" |
| Post_message_in_a_chat_or_channel | OpenApiConnection | Get_an_-at-mention_token_for_a_user | <pre>{<br>  "host": {<br>    "apiId": "/providers/Microsoft.PowerApps/apis/shared_teams",<br>    "connectionName": "shared_teams",<br>    "operationId": "PostMessageToConversation"<br>  },<br>  "parameters": {<br>    "poster": "Flow bot",<br>    "location": "Group chat",<br>    "body/recipient": "19:70e0bb050895486cbf100a5bac7a937d@thread.v2",<br>    "body/messageBody": " @{outputs('Get_an_@mention_token_for_a_user')?['body/atMention']} Congratulations with your birthday!\n<p>\n<img src=\"@{outputs('Compose_-_Output_Giphy_Birtday_url')}\" width=\"275\" height=\"250\" alt=\"Gihpy birtday image (GIF Image)\" style=\"padding-top:5px\">\n<p>\n<p>Interesting fact.</p>\n@{variables('varInterestingFact')}\n<p>\n<p>Have a great day!</p>\n<p>\n<p>Stefan Stranger</p>\n</p>\n"<br>  },<br>  "authentication": "@parameters('$authentication')"<br>}</pre> |
| Parse_JSON | ParseJson | Condition | |
| Condition | If | Get_message_details | null |
| Get_message_details | OpenApiConnection | Apply_to_each | <pre>{<br>  "host": {<br>    "apiId": "/providers/Microsoft.PowerApps/apis/shared_teams",<br>    "connectionName": "shared_teams",<br>    "operationId": "GetMessageDetails"<br>  },<br>  "parameters": {<br>    "messageId": "@items('Apply_to_each')?['messageId']",<br>    "threadType": "groupchat",<br>    "body/recipient": "19:70e0bb050895486cbf100a5bac7a937d@thread.v2"<br>  },<br>  "authentication": "@parameters('$authentication')"<br>}</pre> |
| Compose_-_Get_messageid_property_from_first_Teams_Chat_message | Compose | Condition_-_Check_for_empty_varDutchPeopleBirthdays | "@first(triggerOutputs()?['body/value'])?['messageId']" |
| Apply_to_each | Foreach | Compose_-_Get_messageid_property_from_first_Teams_Chat_message | null |

## Logic App Connections

This section shows an overview of Logic App Workflow connections.
