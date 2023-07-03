# Introduction

This is a script to generate technical documentation for Azure Logic Apps. It uses PowerShell to retrieve the Logic App Workflow code and creates a Markdown file with the workflow in a Mermaid Diagram and a table of the actions used in the workflow.

## Getting Started

Clone the repository and run the script. The script will prompt you for the parameters. It will then create a Markdown file in the directory you provided when running the script.

```powershell
# Clone the repository
git clone https://github.com/stefanstranger/logicappdocs.git
```

## Run the script

Navigate to the folder where you have cloned the repository and run the script.

```powershell
# Authenticate to Azure where the Azure Logic App is located
Login-AzAccount -SubscriptionId <SubscriptionId>

# Run the script
.\src\New-LogicAppDoc.ps1 -SubscriptionId <SubscriptionId> -ResourceGroupName <ResourceGroupName> -LogicAppName <LogicAppName> -OutputPath <OutputDirectory>
```

## Open the Markdown file

You can open the Markdown file in Visual Studio Code or any other Markdown editor.

Go to the directory where you have saved the Markdown file (OutputPath) and open the file called Azure-LogicApp-Documentation.md.

## Example

![Example of the generated Markdown file](./examplemarkdowndocument.png)



