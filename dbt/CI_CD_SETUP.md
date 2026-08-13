# dbt Cloud CI/CD Setup — FinPulse

Most of this phase is dbt Cloud UI configuration rather than files, so this
doc is the source of truth for what's configured and why.

## Environments
| Name | Type | Purpose |
|---|---|---|
| CI | CI | Ephemeral per-PR schema builds |
| Production | Deployment | Scheduled daily builds against real schemas |

## Jobs

### CI — PR Checks
- Trigger: Run on Pull Requests (native dbt Cloud GitHub integration)
- Command: `dbt build`
- Result: posted as a GitHub check on the PR — failing tests block merge
  from being "clean," same as any standard CI gate

### Production — Daily Build
- Trigger: Scheduled, daily 07:00 UTC (after upstream loads land)
- Commands: `dbt snapshot` then `dbt build`
  (snapshot runs first so SCD2 captures changes before Silver/Gold rebuild)
- Notification: Webhook → Logic App (finpulse-la-alerts) on failure

## Known integration detail
dbt Cloud's webhook payload schema differs from the ADF Web activity
payload our Logic App was originally built for. A Parse JSON action was
added in the Logic App to normalize both shapes before the Teams/Slack
notification step. See `logic_apps/logic_app.bicep`.

## Why CI matters here
Without CI, a broken model or failing test could merge into main and only
surface during the next scheduled production run — potentially hours
later, against real data. The PR check catches it before merge, using a
disposable schema so it costs nothing to run repeatedly.
