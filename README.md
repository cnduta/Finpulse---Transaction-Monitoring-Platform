# FinPulse — Transaction Monitoring & Regulatory Reporting Platform

## What this is
A hybrid Azure + Snowflake data platform simulating a real-world financial
services data engineering workflow: multi-currency transaction ingestion
(streaming + batch), incremental loading with watermarking, CDC-driven
transformation, SCD Type 2 dimensional modelling, automated testing/CI, and
compliance-oriented dashboards.

This project intentionally simulates a *running* system rather than a
one-time load — see `docs/RUNLOG.md` for a day-by-day log of a week-long
simulation including injected failures, late-arriving data, and recovery.

## Why this exists
Built to demonstrate hands-on, production-style data engineering practices
(incremental loads, CDC, CI/CD, observability, governance) in a domain
(financial transaction monitoring) that reflects real prior experience in
banking/financial services reporting.

## Architecture

```
Event Hubs (streaming) ─┐
                         ├─> ADLS Gen2 (Bronze/raw) ─> Snowflake ─> dbt (Bronze/Silver/Gold) ─> Power BI
ADF (batch, watermarked)┘         ^                        ^
                                   |                        |
                            Azure Key Vault           Snowflake Streams + Tasks (CDC)
                                   |
                          Logic Apps (failure alerts)
                                   |
                          Microsoft Purview (classification, lineage, glossary)
```

**Why hybrid Azure + Snowflake:** ADF's connector ecosystem and metadata-driven
pipeline pattern suit heterogeneous source ingestion (APIs, reference data,
SFTP-style feeds), while Snowflake's separated storage/compute and native
Streams/Tasks give more efficient CDC and elastic analytical compute than
running the equivalent in a Synapse dedicated pool for this workload.

## Repo structure
- `infra/bicep/` — Infrastructure as Code (Event Hubs, ADLS Gen2, Key Vault)
- `ingestion/eventhub_producer/` — Python streaming producer (simulated transactions)
- `ingestion/adf/` — ADF pipeline definitions + watermark control table logic
- `snowflake/sql/` — Warehouse/database/schema setup, Streams, Tasks
- `dbt/` — dbt Cloud project (Bronze/Silver/Gold models, tests, SCD Type 2)
- `logic_apps/` — Failure alerting workflow definitions
- `purview/` — Classification, glossary, lineage documentation
- `powerbi/` — Dashboard documentation (screenshots, data model notes)
- `docs/RUNLOG.md` — Week-long simulation log

## Status
🚧 In progress — built incrementally, phase by phase. See `docs/RUNLOG.md`
for what's been tested so far.

## Disclaimer
This is a portfolio/demo project using synthetic data. Transaction flagging
logic is simple rules-based thresholding, not a production AML system.
Purview classification/lineage is configured on demo data; access policies
are documented but not enforced via a live IdP integration.
