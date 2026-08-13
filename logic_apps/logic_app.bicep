// FinPulse — Logic App: Pipeline Failure Alerting
// Deploy separately from main.bicep since workflow definitions are large;
// keeps main.bicep focused on core data infra.
// Deploy with: az deployment group create --template-file logic_app.bicep ...

@description('Azure region')
param location string = 'uksouth'

@description('Short project name')
param projectName string = 'finpulse'

@description('Environment name')
param environment string = 'dev'

var uniqueSuffix = uniqueString(resourceGroup().id)
var logicAppName = toLower('${projectName}-la-alerts-${environment}-${uniqueSuffix}')

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        // HTTP-triggered webhook. ADF's Web activity and dbt Cloud's
        // webhook notifications will both POST here on failure.
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              type: 'object'
              properties: {
                source: { type: 'string' }        // e.g. "ADF" or "dbt Cloud"
                pipeline_name: { type: 'string' }
                status: { type: 'string' }
                error_message: { type: 'string' }
                run_time: { type: 'string' }
              }
            }
          }
        }
      }
      actions: {
        // Simplest fully-automatable notification: post to a Teams
        // incoming webhook (or Slack — same pattern). Swap the URL for
        // your own channel's webhook.
        Post_to_Teams: {
          type: 'Http'
          inputs: {
            method: 'POST'
            uri: '<your-teams-or-slack-webhook-url>'
            headers: {
              'Content-Type': 'application/json'
            }
            body: {
              text: '🚨 FinPulse pipeline failure\nSource: @{triggerBody()?[\'source\']}\nPipeline: @{triggerBody()?[\'pipeline_name\']}\nError: @{triggerBody()?[\'error_message\']}\nTime: @{triggerBody()?[\'run_time\']}'
            }
          }
        }
      }
    }
  }
}

output logicAppTriggerUrl string = listCallbackUrl('${logicApp.id}/triggers/manual', '2019-05-01').value
