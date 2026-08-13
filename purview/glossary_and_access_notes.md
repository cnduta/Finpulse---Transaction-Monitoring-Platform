# Purview Glossary Terms — FinPulse

Create these in Purview Studio (Data Map → Glossary → New term), then link
each to the relevant asset(s) via the term's "Assigned assets" tab.

| Term | Definition | Link to asset |
|---|---|---|
| Flagged Transaction | A transaction where `is_flagged = true`, determined by rules-based thresholding (amount > 10,000 OR high-risk country) — not a production AML determination | `gold_fact_transactions.is_flagged` |
| High-Risk Country | A country in the project's static watch list used for simple transaction flagging | `bronze_transactions.is_high_risk_country` |
| SCD Type 2 Account Dimension | Slowly Changing Dimension tracking historical changes to account/customer attributes over time, maintained via dbt snapshots fed by Snowflake CDC | `snap_accounts` |
| Watermark | The last successfully processed value per source, used to drive incremental/idempotent pipeline loads | `watermark_control` table |

## Note on scope
Classification and lineage in this project are configured on synthetic
demo data for portfolio purposes. Access policies below are documented
as intended design, not enforced via a live identity provider integration.

## Documented intended access policy (not live-enforced)
- Raw layer (`raw` schema): Data Engineering role only
- Staging/Silver: Data Engineering + Analytics roles
- Gold/Analytics: broader read access for reporting consumers
- `customer_name`, `account_id`: should be masked/restricted for any role
  without a documented compliance need — in production this would use
  Snowflake's Dynamic Data Masking policies tied to role, not just Purview
  labels
