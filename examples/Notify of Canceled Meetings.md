# PowerAutomate Flow Documentation - Notify of Canceled Meetings

## Introduction

This document describes the PowerAutomate Flow **Notify of Canceled Meetings** in the **839abcd7-59ab-4243-97ec-a5b8fcc104e4** Environment.

This document is programmatically generated using a PowerShell script.

Date: 2023-08-05 16:28:57

## PowerAutomate Flow Diagram

```mermaid
graph TB
    When_an_event_is_added,_updated_or_deleted_(V3)
    subgraph Check_if_event_is_cancelled
    direction TB
        Cancel_Keywords
        Set_IsCancelled_variable
        FirstPhrase
        SplitSubject
    end
    subgraph If_Event_is_Cancelled-True
    direction TB
        Delete_event__V2_
        If_Event_is_not_a_part_of_series
        Set_DAWActSuccess_to_True
    end
    subgraph If_Event_is_not_a_part_of_series-True
    direction TB
        Convert_time_zone_of_Start_Time
        Convert_time_zone_of_End_Time
        Get_my_profile__V2_
        Post_adaptive_card_in_a_chat_or_channel
        Card
    end
    subgraph Initialize_Default_Calendar
    direction TB
        Get_calendars__V2_
        Calendars
    end
    subgraph Initialize_User_Time_Zone
    direction TB
        TZ
        TimeZones
    end
    Check_if_event_is_cancelled --> If_Event_is_Cancelled
    If_Event_is_Cancelled --> Delete_event__V2_
    Delete_event__V2_ --> If_Event_is_not_a_part_of_series
    If_Event_is_not_a_part_of_series --> Convert_time_zone_of_Start_Time
    Convert_time_zone_of_Start_Time --> Convert_time_zone_of_End_Time
    Convert_time_zone_of_End_Time --> Get_my_profile__V2_
    Card --> Post_adaptive_card_in_a_chat_or_channel
    Get_my_profile__V2_ --> Card
    If_Event_is_not_a_part_of_series --> Set_DAWActSuccess_to_True
    Initialize_ImageBaseUrl_variable --> Initialize_IsEventCancelled_variable
    Initialize_DAWActFailure_Failure --> Check_if_event_is_cancelled
    FirstPhrase --> Cancel_Keywords
    Cancel_Keywords --> Set_IsCancelled_variable
    SplitSubject --> FirstPhrase
    Check_if_event_is_cancelled --> SplitSubject
    Initialize_Default_Calendar --> Initialize_MyCalendar_variable
    Initialize_IsEventCancelled_variable --> Initialize_DAWActSuccess_Flag
    Initialize_DAWActSuccess_Flag --> Initialize_DAWActFailure_Failure
    If_Event_is_Cancelled --> Set_DAWActFailure_to_True
    Initialize_User_Time_Zone --> Initialize_TimeZone_variable
    Initialize_CancelationPrefix_variable --> Initialize_Default_Calendar
    Initialize_Default_Calendar --> Get_calendars__V2_
    Get_calendars__V2_ --> Calendars
    Initialize_MyCalendar_variable --> Initialize_User_Time_Zone
    Initialize_User_Time_Zone --> TZ
    TZ --> TimeZones
    Initialize_EventSubject_variable --> Initialize_ImageBaseUrl_variable
    Initialize_TimeZone_variable --> Initialize_EventSubject_variable
    When_an_event_is_added,_updated_or_deleted_(V3) --> Initialize_CancelationPrefix_variable

```


## PowerAutomate Flow Actions

This section shows an overview of PowerAutomate Flow actions and their dependencies.

### PowerAutomate Flow Triggers

| Name | Type | Inputs |
| ---- | ---- | ------ |
| When_an_event_is_added,_updated_or_deleted_(V3) | OpenApiConnectionNotification | <pre>{<br>  "host": {<br>    "apiId": "/providers/Microsoft.PowerApps/apis/shared_office365",<br>    "connectionName": "shared_office365",<br>    "operationId": "CalendarGetOnChangedItemsV3"<br>  },<br>  "parameters": {<br>    "table": "********",<br>    "incomingDays": 300,<br>    "pastDays": 0<br>  },<br>  "authentication": "@parameters('$authentication')"<br>}</pre> |

### Actions

| ActionName | Type | RunAfter | Inputs |
| ---------- | ---- | -------- | ------ |
| Initialize_CancelationPrefix_variable | InitializeVariable |  | <pre>{<br>  "variables": [<br>    {<br>      "name": "CancelationPrefix",<br>      "type": "string",<br>      "value": "Canceled"<br>    }<br>  ]<br>}</pre> |
| Initialize_Default_Calendar | Scope | Initialize_CancelationPrefix_variable | null |
| Get_calendars__V2_ | OpenApiConnection | Initialize_Default_Calendar | <pre>{<br>  "host": {<br>    "apiId": "/providers/Microsoft.PowerApps/apis/shared_office365",<br>    "connectionName": "shared_office365",<br>    "operationId": "CalendarGetTables_V2"<br>  },<br>  "parameters": {},<br>  "authentication": "@parameters('$authentication')"<br>}</pre> |
| Calendars | Query | Get_calendars__V2_ | <pre>{<br>  "from": "@outputs('Get_calendars_(V2)')?['body/value']",<br>  "where": "@equals(item()['isDefaultCalendar'], true)"<br>}</pre> |
| Initialize_MyCalendar_variable | InitializeVariable | Initialize_Default_Calendar | <pre>{<br>  "variables": [<br>    {<br>      "name": "MyCalendar",<br>      "type": "string",<br>      "value": "@{first(body('Calendars'))['Id']}"<br>    }<br>  ]<br>}</pre> |
| Initialize_User_Time_Zone | Scope | Initialize_MyCalendar_variable | null |
| TZ | OpenApiConnection | Initialize_User_Time_Zone | <pre>{<br>  "host": {<br>    "apiId": "/providers/Microsoft.PowerApps/apis/shared_office365",<br>    "connectionName": "shared_office365",<br>    "operationId": "V4CalendarPostItem"<br>  },<br>  "parameters": {<br>    "table": "@variables('MyCalendar')",<br>    "item/subject": "None",<br>    "item/start": "@utcNow()",<br>    "item/end": "@addHours(utcNow(),-1)",<br>    "item/timeZone": "(UTC-08:00) Pacific Time (US & Canada)"<br>  },<br>  "authentication": "@parameters('$authentication')"<br>}</pre> |
| TimeZones | Compose | TZ | <pre>{<br>  "(UTC-12:00) International Date Line West": "Dateline Standard Time",<br>  "(UTC-11:00) Coordinated Universal Time-11": "UTC-11",<br>  "(UTC-10:00) Aleutian Islands": "Aleutian Standard Time",<br>  "(UTC-10:00) Hawaii": "Hawaiian Standard Time",<br>  "(UTC-09:30) Marquesas Islands": "Marquesas Standard Time",<br>  "(UTC-09:00) Alaska": "Alaskan Standard Time",<br>  "(UTC-09:00) Coordinated Universal Time-09": "UTC-09",<br>  "(UTC-08:00) Baja California": "Pacific Standard Time (Mexico)",<br>  "(UTC-08:00) Coordinated Universal Time-08": "UTC-08",<br>  "(UTC-08:00) Pacific Time (US & Canada)": "Pacific Standard Time",<br>  "(UTC-07:00) Arizona": "US Mountain Standard Time",<br>  "(UTC-07:00) Chihuahua, La Paz, Mazatlan": "Mountain Standard Time (Mexico)",<br>  "(UTC-07:00) Mountain Time (US & Canada)": "Mountain Standard Time",<br>  "(UTC-06:00) Central America": "Central America Standard Time",<br>  "(UTC-06:00) Central Time (US & Canada)": "Central Standard Time",<br>  "(UTC-06:00) Easter Island": "Easter Island Standard Time",<br>  "(UTC-06:00) Guadalajara, Mexico City, Monterrey": "Central Standard Time (Mexico)",<br>  "(UTC-06:00) Saskatchewan": "Canada Central Standard Time",<br>  "(UTC-05:00) Bogota, Lima, Quito, Rio Branco": "SA Pacific Standard Time",<br>  "(UTC-05:00) Chetumal": "Eastern Standard Time (Mexico)",<br>  "(UTC-05:00) Eastern Time (US & Canada)": "Eastern Standard Time",<br>  "(UTC-05:00) Haiti": "Haiti Standard Time",<br>  "(UTC-05:00) Havana": "Cuba Standard Time",<br>  "(UTC-05:00) Indiana (East)": "US Eastern Standard Time",<br>  "(UTC-04:00) Asuncion": "Paraguay Standard Time",<br>  "(UTC-04:00) Atlantic Time (Canada)": "Atlantic Standard Time",<br>  "(UTC-04:00) Caracas": "Venezuela Standard Time",<br>  "(UTC-04:00) Cuiaba": "Central Brazilian Standard Time",<br>  "(UTC-04:00) Georgetown, La Paz, Manaus, San Juan": "SA Western Standard Time",<br>  "(UTC-04:00) Santiago": "Pacific SA Standard Time",<br>  "(UTC-04:00) Turks and Caicos": "Turks And Caicos Standard Time",<br>  "(UTC-03:30) Newfoundland": "Newfoundland Standard Time",<br>  "(UTC-03:00) Araguaina": "Tocantins Standard Time",<br>  "(UTC-03:00) Brasilia": "E. South America Standard Time",<br>  "(UTC-03:00) Cayenne, Fortaleza": "SA Eastern Standard Time",<br>  "(UTC-03:00) City of Buenos Aires": "Argentina Standard Time",<br>  "(UTC-03:00) Greenland": "Greenland Standard Time",<br>  "(UTC-03:00) Montevideo": "Montevideo Standard Time",<br>  "(UTC-03:00) Punta Arenas": "SA Eastern Standard Time",<br>  "(UTC-03:00) Saint Pierre and Miquelon": "Saint Pierre Standard Time",<br>  "(UTC-03:00) Salvador": "Bahia Standard Time",<br>  "(UTC-02:00) Coordinated Universal Time-02": "UTC-02",<br>  "(UTC-02:00) Mid-Atlantic - Old": "Mid-Atlantic Standard Time",<br>  "(UTC-01:00) Azores": "Azores Standard Time",<br>  "(UTC-01:00) Cabo Verde Is.": "Cape Verde Standard Time",<br>  "(UTC) Coordinated Universal Time": "UTC",<br>  "(UTC+00:00) Casablanca": "Morocco Standard Time",<br>  "(UTC+00:00) Dublin, Edinburgh, Lisbon, London": "GMT Standard Time",<br>  "(UTC+00:00) Monrovia, Reykjavik": "Greenwich Standard Time",<br>  "(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna": "W. Europe Standard Time",<br>  "(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague": "Central Europe Standard Time",<br>  "(UTC+01:00) Brussels, Copenhagen, Madrid, Paris": "Romance Standard Time",<br>  "(UTC+01:00) Sarajevo, Skopje, Warsaw, Zagreb": "Central European Standard Time",<br>  "(UTC+01:00) West Central Africa": "W. Central Africa Standard Time",<br>  "(UTC+01:00) Windhoek": "Namibia Standard Time",<br>  "(UTC+02:00) Amman": "Jordan Standard Time",<br>  "(UTC+02:00) Athens, Bucharest": "GTB Standard Time",<br>  "(UTC+02:00) Beirut": "Middle East Standard Time",<br>  "(UTC+02:00) Cairo": "Egypt Standard Time",<br>  "(UTC+02:00) Chisinau": "E. Europe Standard Time",<br>  "(UTC+02:00) Damascus": "Syria Standard Time",<br>  "(UTC+02:00) Gaza, Hebron": "West Bank Standard Time",<br>  "(UTC+02:00) Harare, Pretoria": "South Africa Standard Time",<br>  "(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius": "FLE Standard Time",<br>  "(UTC+02:00) Jerusalem": "Israel Standard Time",<br>  "(UTC+02:00) Kaliningrad": "Kaliningrad Standard Time",<br>  "(UTC+02:00) Tripoli": "Libya Standard Time",<br>  "(UTC+03:00) Baghdad": "Arabic Standard Time",<br>  "(UTC+03:00) Istanbul": "Turkey Standard Time",<br>  "(UTC+03:00) Kuwait, Riyadh": "Arab Standard Time",<br>  "(UTC+03:00) Minsk": "Belarus Standard Time",<br>  "(UTC+03:00) Moscow, St. Petersburg": "Russian Standard Time",<br>  "(UTC+03:00) Nairobi": "E. Africa Standard Time",<br>  "(UTC+03:30) Tehran": "Iran Standard Time",<br>  "(UTC+04:00) Abu Dhabi, Muscat": "Arabian Standard Time",<br>  "(UTC+04:00) Astrakhan, Ulyanovsk": "Astrakhan Standard Time",<br>  "(UTC+04:00) Baku": "Azerbaijan Standard Time",<br>  "(UTC+04:00) Izhevsk, Samara": "Russia Time Zone 3",<br>  "(UTC+04:00) Port Louis": "Mauritius Standard Time",<br>  "(UTC+04:00) Saratov": "Russia Time Zone 3",<br>  "(UTC+04:00) Tbilisi": "Georgian Standard Time",<br>  "(UTC+04:00) Volgograd": "Russian Standard Time",<br>  "(UTC+04:00) Yerevan": "Caucasus Standard Time",<br>  "(UTC+04:30) Kabul": "Afghanistan Standard Time",<br>  "(UTC+05:00) Ashgabat, Tashkent": "West Asia Standard Time",<br>  "(UTC+05:00) Ekaterinburg": "Ekaterinburg Standard Time",<br>  "(UTC+05:00) Islamabad, Karachi": "Pakistan Standard Time",<br>  "(UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi": "India Standard Time",<br>  "(UTC+05:30) Sri Jayawardenepura": "Sri Lanka Standard Time",<br>  "(UTC+05:45) Kathmandu": "Nepal Standard Time",<br>  "(UTC+06:00) Astana": "Central Asia Standard Time",<br>  "(UTC+06:00) Dhaka": "Bangladesh Standard Time",<br>  "(UTC+06:00) Omsk": "Central Asia Standard Time",<br>  "(UTC+06:30) Yangon (Rangoon)": "Myanmar Standard Time",<br>  "(UTC+07:00) Bangkok, Hanoi, Jakarta": "SE Asia Standard Time",<br>  "(UTC+07:00) Barnaul, Gorno-Altaysk": "Altai Standard Time",<br>  "(UTC+07:00) Hovd": "W. Mongolia Standard Time",<br>  "(UTC+07:00) Krasnoyarsk": "North Asia Standard Time",<br>  "(UTC+07:00) Novosibirsk": "North Asia Standard Time",<br>  "(UTC+07:00) Tomsk": "Tomsk Standard Time",<br>  "(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi": "China Standard Time",<br>  "(UTC+08:00) Irkutsk": "North Asia East Standard Time",<br>  "(UTC+08:00) Kuala Lumpur, Singapore": "Singapore Standard Time",<br>  "(UTC+08:00) Perth": "W. Australia Standard Time",<br>  "(UTC+08:00) Taipei": "Taipei Standard Time",<br>  "(UTC+08:00) Ulaanbaatar": "Ulaanbaatar Standard Time",<br>  "(UTC+08:30) Pyongyang": "North Korea Standard Time",<br>  "(UTC+08:45) Eucla": "Aus Central W. Standard Time",<br>  "(UTC+09:00) Chita": "Transbaikal Standard Time",<br>  "(UTC+09:00) Osaka, Sapporo, Tokyo": "Tokyo Standard Time",<br>  "(UTC+09:00) Seoul": "Korea Standard Time",<br>  "(UTC+09:00) Yakutsk": "Yakutsk Standard Time",<br>  "(UTC+09:30) Adelaide": "Cen. Australia Standard Time",<br>  "(UTC+09:30) Darwin": "AUS Central Standard Time",<br>  "(UTC+10:00) Brisbane": "E. Australia Standard Time",<br>  "(UTC+10:00) Canberra, Melbourne, Sydney": "AUS Eastern Standard Time",<br>  "(UTC+10:00) Guam, Port Moresby": "West Pacific Standard Time",<br>  "(UTC+10:00) Hobart": "Tasmania Standard Time",<br>  "(UTC+10:00) Vladivostok": "Vladivostok Standard Time",<br>  "(UTC+10:30) Lord Howe Island": "Lord Howe Standard Time",<br>  "(UTC+11:00) Bougainville Island": "Bougainville Standard Time",<br>  "(UTC+11:00) Chokurdakh": "Russia Time Zone 10",<br>  "(UTC+11:00) Magadan": "Magadan Standard Time",<br>  "(UTC+11:00) Norfolk Island": "Norfolk Standard Time",<br>  "(UTC+11:00) Sakhalin": "Sakhalin Standard Time",<br>  "(UTC+11:00) Solomon Is., New Caledonia": "Central Pacific Standard Time",<br>  "(UTC+12:00) Anadyr, Petropavlovsk-Kamchatsky": "Russia Time Zone 11",<br>  "(UTC+12:00) Auckland, Wellington": "New Zealand Standard Time",<br>  "(UTC+12:00) Coordinated Universal Time+12": "UTC+12",<br>  "(UTC+12:00) Fiji": "Fiji Standard Time",<br>  "(UTC+12:00) Petropavlovsk-Kamchatsky - Old": "Kamchatka Standard Time",<br>  "(UTC+12:45) Chatham Islands": "Chatham Islands Standard Time",<br>  "(UTC+13:00) Coordinated Universal Time+13": "Samoa Standard Time",<br>  "(UTC+13:00) Nuku'alofa": "Tonga Standard Time",<br>  "(UTC+13:00) Samoa": "Samoa Standard Time",<br>  "(UTC+14:00) Kiritimati Island": "Line Islands Standard Time"<br>}</pre> |
| Initialize_TimeZone_variable | InitializeVariable | Initialize_User_Time_Zone | <pre>{<br>  "variables": [<br>    {<br>      "name": "TimeZone",<br>      "type": "string",<br>      "value": "@{outputs('TimeZones')[actions('TZ')['inputs']['parameters']['item/timeZone']]}"<br>    }<br>  ]<br>}</pre> |
| Initialize_EventSubject_variable | InitializeVariable | Initialize_TimeZone_variable | <pre>{<br>  "variables": [<br>    {<br>      "name": "EventSubject",<br>      "type": "string",<br>      "value": "@{replace(replace(triggerOutputs()?['body/subject'],'\\','\\\\'),'\"','\\\"')}"<br>    }<br>  ]<br>}</pre> |
| Initialize_ImageBaseUrl_variable | InitializeVariable | Initialize_EventSubject_variable | <pre>{<br>  "variables": [<br>    {<br>      "name": "ImageBaseUrl",<br>      "type": "string",<br>      "value": "https://imageafetssa.z5.web.core.windows.net/images/EmailThumbnail.png"<br>    }<br>  ]<br>}</pre> |
| Initialize_IsEventCancelled_variable | InitializeVariable | Initialize_ImageBaseUrl_variable | <pre>{<br>  "variables": [<br>    {<br>      "name": "IsEventCancelled",<br>      "type": "boolean",<br>      "value": "@false"<br>    }<br>  ]<br>}</pre> |
| Initialize_DAWActSuccess_Flag | InitializeVariable | Initialize_IsEventCancelled_variable | <pre>{<br>  "variables": [<br>    {<br>      "name": "DAWActSuccess",<br>      "type": "boolean",<br>      "value": "@false"<br>    }<br>  ]<br>}</pre> |
| Initialize_DAWActFailure_Failure | InitializeVariable | Initialize_DAWActSuccess_Flag | <pre>{<br>  "variables": [<br>    {<br>      "name": "DAWActFailure",<br>      "type": "boolean",<br>      "value": "@false"<br>    }<br>  ]<br>}</pre> |
| Check_if_event_is_cancelled | Scope | Initialize_DAWActFailure_Failure | null |
| SplitSubject | Compose | Check_if_event_is_cancelled | "@split(triggerOutputs()?['body/subject'],':')" |
| FirstPhrase | Compose | SplitSubject | "@trim(first(outputs('SplitSubject')))" |
| Cancel_Keywords | Compose | FirstPhrase | [<br>  "Canceled",<br>  "Abgesagt",<br>  "Cancelada",<br>  "取り消し",<br>  "Cancelled",<br>  "@{variables('CancelationPrefix')}"<br>] |
| Set_IsCancelled_variable | SetVariable | Cancel_Keywords | <pre>{<br>  "name": "IsEventCancelled",<br>  "value": "@contains(outputs('Cancel_Keywords'), outputs('FirstPhrase'))"<br>}</pre> |
| If_Event_is_Cancelled | If | Check_if_event_is_cancelled | null |
| Delete_event__V2_ | OpenApiConnection | If_Event_is_Cancelled-True | <pre>{<br>  "host": {<br>    "apiId": "/providers/Microsoft.PowerApps/apis/shared_office365",<br>    "connectionName": "shared_office365",<br>    "operationId": "CalendarDeleteItem_V2"<br>  },<br>  "parameters": {<br>    "calendar": "@trigger()['inputs']['parameters']['table']",<br>    "event": "@triggerOutputs()?['body/id']"<br>  },<br>  "authentication": "@parameters('$authentication')"<br>}</pre> |
| If_Event_is_not_a_part_of_series | If | Delete_event__V2_ | null |
| Convert_time_zone_of_Start_Time | Expression | If_Event_is_not_a_part_of_series-True | <pre>{<br>  "baseTime": "@{triggerOutputs()?['body/start']}z",<br>  "formatString": "f",<br>  "sourceTimeZone": "UTC",<br>  "destinationTimeZone": "@variables('TimeZone')"<br>}</pre> |
| Convert_time_zone_of_End_Time | Expression | Convert_time_zone_of_Start_Time | <pre>{<br>  "baseTime": "@{triggerOutputs()?['body/end']}z",<br>  "formatString": "f",<br>  "sourceTimeZone": "UTC",<br>  "destinationTimeZone": "@variables('TimeZone')"<br>}</pre> |
| Get_my_profile__V2_ | OpenApiConnection | Convert_time_zone_of_End_Time | <pre>{<br>  "host": {<br>    "apiId": "/providers/Microsoft.PowerApps/apis/shared_office365users",<br>    "connectionName": "shared_office365users",<br>    "operationId": "MyProfile_V2"<br>  },<br>  "parameters": {<br>    "$select": "Mail"<br>  },<br>  "authentication": "@parameters('$authentication')"<br>}</pre> |
| Card | Compose | Get_my_profile__V2_ | <pre>{<br>  "type": "AdaptiveCard",<br>  "body": [<br>    {<br>      "type": "ColumnSet",<br>      "columns": [<br>        {<br>          "type": "Column",<br>          "width": "auto",<br>          "items": [<br>            {<br>              "type": "Image",<br>              "url": "@{variables('ImageBaseUrl')}",<br>              "size": "Medium",<br>              "id": "logo",<br>              "altText": "logo"<br>            }<br>          ],<br>          "spacing": "Small"<br>        },<br>        {<br>          "type": "Column",<br>          "width": "stretch",<br>          "items": [<br>            {<br>              "type": "TextBlock",<br>              "wrap": true,<br>              "text": "The event **@{variables('EventSubject')}** which was scheduled from **@{body('Convert_time_zone_of_Start_Time')}** to **@{body('Convert_time_zone_of_End_Time')}** has been canceled and this automation has removed the event from your calendar.",<br>              "size": "Default"<br>            }<br>          ]<br>        }<br>      ]<br>    },<br>    {<br>      "type": "TextBlock",<br>      "text": "[Turn Off or Update Automation](https://flow.microsoft.com/manage/environments/@{workflow()?['tags']?['environmentName']}/flows/@{workflow()?['tags']?['logicAppName']}/details), [Get Help](https://aka.ms/automationsfaq), [Report An Issue](https://aka.ms/automationsreportissue), [Give Feedback](https://aka.ms/automationsfeedback), [Run Details](https://flow.microsoft.com/manage/environments/@{workflow()?['tags']?['environmentName']}/flows/@{workflow()?['tags']?['logicAppName']}/runs/@{workflow()?['run']?['name']})",<br>      "wrap": true,<br>      "size": "Small",<br>      "spacing": "Small",<br>      "weight": "Lighter"<br>    }<br>  ],<br>  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",<br>  "version": "1.3"<br>}</pre> |
| Post_adaptive_card_in_a_chat_or_channel | OpenApiConnection | Card | <pre>{<br>  "host": {<br>    "apiId": "/providers/Microsoft.PowerApps/apis/shared_teams",<br>    "connectionName": "shared_teams",<br>    "operationId": "PostCardToConversation"<br>  },<br>  "parameters": {<br>    "poster": "Flow bot",<br>    "location": "Chat with Flow bot",<br>    "body/recipient": "@{outputs('Get_my_profile_(V2)')?['body/mail']};",<br>    "body/messageBody": "@outputs('Card')"<br>  },<br>  "authentication": "@parameters('$authentication')"<br>}</pre> |
| Set_DAWActFailure_to_True | SetVariable | If_Event_is_Cancelled | <pre>{<br>  "name": "DAWActFailure",<br>  "value": "@true"<br>}</pre> |
| Set_DAWActSuccess_to_True | SetVariable | If_Event_is_Cancelled-True | <pre>{<br>  "name": "DAWActSuccess",<br>  "value": "@true"<br>}</pre> |

## PowerAutomate Flow Connections

This section shows an overview of PowerAutomate Flow connections.

### Connections

| ConnectionName | ConnectionId |
| -------------- | ------------ |
| shared-office365-7f77safe-18d0-4f86-ada7-ae5d756b96e9 | /providers/Microsoft.PowerApps/apis/shared_office365 |
| 2afc0e3e83f241asdf8c182e910085055c | /providers/Microsoft.PowerApps/apis/shared_office365users |
| shared-teams-69ea0166-7e4f-4033-b861-c64a30c2cb27 | /providers/Microsoft.PowerApps/apis/shared_teams |
