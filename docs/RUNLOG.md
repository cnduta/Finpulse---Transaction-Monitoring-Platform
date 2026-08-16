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

## Day 2 (cont'd) — Streaming pipeline verified end-to-end
- Confirmed Event Hubs Capture writing real Avro files to raw-streaming
  container, correct partitioned folder structure
  (finpulse-ehns-dev-.../transactions/{partition}/{year}/{month}/{day}/{hour}/{minute}/{second})
- CLI blob listing hit a Cloud Shell managed-identity token timeout issue
  (known quirk) — verified via Portal Storage Browser instead
- Phase 2 (streaming ingestion) fully verified end-to-end: producer -> Event Hub -> Capture -> ADLS

## Day 3 — Snowflake Storage Integration (Azure AD trust)
- Created STORAGE INTEGRATION in Snowflake, generated AZURE_CONSENT_URL
- Consent flow completed (redirected to snowflake.com with valid OAuth code)
- Enterprise app not immediately visible in Portal search or via
  `az ad sp show` (also hit a Cloud Shell Graph token timeout, separate
  known quirk, unresolved for now)
- Per Snowflake docs: Azure can take 1-2 hours to actually provision the
  service principal after consent — this is expected propagation delay,
  not a configuration error
- Action: wait, then retry role assignment
