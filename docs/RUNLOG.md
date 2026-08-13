# RUNLOG — Week-Long Simulation

Purpose: document what actually happened running this pipeline over a week,
including deliberate failure injection, late-arriving data, and recovery.
This is the evidence of hands-on operational experience.

## Day 1 — Initial Load
- Date: 13/08/2026
- Failed: Key Vault name too long (same root cause as storage account earlier)
- Failed: SQL database missing required `location` property
  (unlike storage containers, SQL databases don't inherit location from parent server — must be set explicitly, even as a child resource)
- Both fixed, redeployed and successful

## Day 2 — First Incremental Run
- Date:
- Watermark before/after:
- Result:

## Day 3 — Incremental Run
- Date:
- Result:

## Day 4 — Late-Arriving Record Injection
- Date:
- What was injected:
- How Silver/Gold handled it:
- Observations:

## Day 5 — Update / Duplicate Injection
- Date:
- What was injected:
- SCD Type 2 behaviour observed:

## Day 6 — Forced Failure & Recovery
- Date:
- Failure injected (e.g. bad credential, schema drift):
- Alert received (Logic Apps):
- Recovery steps:
- Data integrity check after recovery:

## Day 7 — Final CI/CD Run & Wrap-up
- Date:
- dbt Cloud CI result:
- Power BI refresh:
- Summary of what this week demonstrated:

## Day 1 (cont'd) — Phase 2: Event Hubs Producer
- Set up Python venv, installed azure-eventhub, azure-identity, faker, python-dotenv
- Hit a bash syntax error using angle-bracket placeholder literally in a command (redirect operator conflict)
- Successfully sent 20 simulated transactions to Event Hub, confirmed in Azure Portal metrics
- Rotated the shared access key after it was exposed during troubleshooting, using `az eventhubs namespace authorization-rule keys renew`
