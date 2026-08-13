# FinPulse — Full Step-by-Step Build Guide

This is the complete roadmap. Work through phases in order — each one
depends on the previous. Tick off items as you go.

---
## Phase 0 — Setup ✅ (done)
- [x] Azure subscription ready
- [x] Snowflake trial (new email) signed up
- [x] Repo scaffolded, pushed to GitHub
- [x] Azure CLI + Bicep CLI installed locally

---
## Phase 1 — Bicep: Core Infrastructure ✅ (done)
- [x] `main.bicep` written: Storage Account (ADLS Gen2), Key Vault, Event Hubs
- [x] `az group create` — create resource group
- [x] `az deployment group validate` — check syntax
- [x] `az deployment group what-if` — preview changes
- [x] `az deployment group create` — deploy for real
- [x] Verify in Azure Portal: storage account has `bronze` and `raw-streaming` containers, Key Vault exists, Event Hub namespace + `transactions` hub exists
- [x] Grant yourself Key Vault Secrets Officer role (needed since we use RBAC auth)

---
## Phase 2 — Ingestion: Streaming + Batch with Watermarking
**2a. Event Hubs Python producer**
- [x] Write `producer.py` using `azure-eventhub` SDK + Managed Identity (or connection string for local dev)
- [x] Generate synthetic transaction events: account_id, amount, currency, country, timestamp, merchant
- [x] Run producer locally, confirm events land in Event Hub (check via Azure Portal metrics)

**2b. Capture streaming data into ADLS**
- [ ] Enable Event Hubs **Capture** feature (built-in, writes Avro files straight to `raw-streaming` container on a time/size window) — simplest path, no separate consumer app needed

**2c. ADF batch pipeline with watermarking**
- [ ] Create ADF instance (via Bicep or Portal)
- [ ] Create a **watermark control table** — small table (Azure SQL or even a JSON file in ADLS) storing `last_loaded_timestamp` per source
- [ ] Build metadata-driven pipeline: Lookup watermark → query source "newer than watermark" → copy to Bronze → update watermark on success
- [ ] Source data: use a free public API (e.g., exchange rates API) as your "reference data" batch source
- [ ] Test: run pipeline twice — second run should pull zero/near-zero new rows if nothing changed

---
## Phase 3 — Land Data in Snowflake
- [ ] Create Snowflake database, schema (`RAW`, `STAGING` etc.), warehouse (X-Small, auto-suspend 60s to control cost)
- [ ] Create a **Storage Integration** + **external stage** pointing at your ADLS containers
- [ ] Set up **Snowpipe** (auto-ingest) OR scheduled `COPY INTO` for batch loads
- [ ] Load both streaming (Avro from Capture) and batch (JSON/CSV from ADF) into raw Snowflake tables
- [ ] Verify row counts match source

---
## Phase 4 — dbt Cloud: Medallion Transformation
- [ ] Connect dbt Cloud to Snowflake (using a dedicated `dbt` service user/role — least privilege)
- [ ] Bronze models: light typing/renaming only, 1:1 with raw
- [ ] Silver models: cleaning, dedup, business rules, incremental materialization
- [ ] Gold models: aggregates, SCD Type 2 customer/account dimension, fact tables for Power BI
- [ ] Add dbt tests: `not_null`, `unique`, `accepted_values` (e.g. currency codes), a custom test (e.g. no negative balances)
- [ ] Generate and review dbt docs (lineage graph) — this becomes part of your Purview story too

---
## Phase 5 — Snowflake Streams + Tasks (CDC)
- [ ] Create a **Stream** on a raw/Bronze table to capture inserts/updates
- [ ] Create a **Task** (scheduled) that consumes the stream and merges into Silver
- [ ] Test: manually UPDATE a row in the source table, confirm the Stream captures it and the Task propagates it correctly into the SCD Type 2 dimension

---
## Phase 6 — Logic Apps: Failure Alerting
- [ ] Create Logic App with an HTTP-trigger webhook
- [ ] Connect it as an ADF pipeline "on failure" activity, and/or a dbt Cloud webhook on job failure
- [ ] Route to email, Teams, or a simple logging endpoint
- [ ] Test: deliberately break something (bad credential) and confirm the alert fires

---
## Phase 7 — Microsoft Purview: Governance
- [ ] Register ADLS Gen2 and Snowflake as data sources in Purview
- [ ] Run a scan, confirm lineage shows ADLS → Snowflake → dbt models
- [ ] Apply sensitivity classifications to PII/financial columns (account number, amount)
- [ ] Create glossary terms (e.g. "flagged transaction", "high-risk country") and link to assets
- [ ] Document (in `purview/README.md`) intended access policies — not necessarily enforced live

---
## Phase 8 — dbt Cloud CI/CD
- [ ] Connect dbt Cloud project to GitHub repo
- [ ] Set up a CI job: triggers `dbt build` against a temp schema on every PR
- [ ] Set up production job: scheduled daily run of `dbt build` (models + tests) against prod schema
- [ ] Add a webhook/notification on job failure (can reuse Logic Apps from Phase 6)

---
## Phase 9 — Power BI Dashboard
- [ ] Connect Power BI directly to Snowflake Gold layer (import or DirectQuery — document which and why)
- [ ] Build data model: relationships between fact/dimension tables
- [ ] Visuals: transaction volume by country/currency, flagged transaction trend, FX exposure, pipeline health (from a small "pipeline run log" table)
- [ ] Publish to Power BI Service, set up scheduled refresh

---
## Phase 10 — Week-Long Simulation
Run daily for 7 days, logging everything in `docs/RUNLOG.md`:
- [ ] Day 1: Initial full load
- [ ] Day 2–3: Daily incremental runs, confirm watermark advances correctly
- [ ] Day 4: Inject a late-arriving/backdated record — observe handling
- [ ] Day 5: Inject an update/duplicate — confirm SCD Type 2 behaves correctly
- [ ] Day 6: Force a failure (bad credential/schema drift) — confirm alert fires, then recover and verify no data loss/duplication
- [ ] Day 7: Final CI/CD run, refresh Power BI, write summary

---
## After completion
- [ ] Record a 2–3 min screen-capture walkthrough (great for LinkedIn/portfolio)
- [ ] Write a short "lessons learned" section in the README (interviewers love this — shows reflection, not just execution)
