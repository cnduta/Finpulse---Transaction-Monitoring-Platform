# Power BI — DAX Measures Reference

Create these in a dedicated "_Measures" table (Modeling → New Table →
`_Measures = {}`) rather than scattering measures across fact tables —
standard practice for a clean model.

```dax
Total Transactions = COUNTROWS(gold_fact_transactions)

Total Volume = SUM(gold_fact_transactions[amount])

Flagged Transactions = 
    CALCULATE(
        COUNTROWS(gold_fact_transactions),
        gold_fact_transactions[is_flagged] = TRUE
    )

Flagged Rate = 
    DIVIDE([Flagged Transactions], [Total Transactions], 0)

Volume Prior Day = 
    CALCULATE(
        [Total Volume],
        DATEADD('Date'[Date], -1, DAY)
    )

Volume DoD Change % = 
    DIVIDE([Total Volume] - [Volume Prior Day], [Volume Prior Day], 0)

-- Conversion funnel placeholder (adapt if you add a cart/checkout event
-- source later — currently this project only models the transaction event)
```

## Visuals to build
| Visual | Fields |
|---|---|
| KPI cards | Total Transactions, Total Volume, Flagged Rate |
| Line chart — volume trend | `Date` (x-axis), Total Volume (y-axis), split by `currency` |
| Bar chart — flagged transactions by country | `country` (x-axis), Flagged Transactions (y-axis) |
| Table — pipeline health | source a small `pipeline_run_log` table (see note below) showing last run status/time per pipeline |
| Matrix — FX exposure | `currency` (rows), `country` (columns), Total Volume (values) |

## Pipeline health table (optional, ties Phase 6 alerting into the dashboard)
If you want a visible "pipeline health" tile rather than only Teams alerts,
have your ADF Stored Procedure activity (Phase 2) and dbt job also write a
row to a simple `pipeline_run_log` table (source_name, status, run_time) —
same idea as the watermark_control table. Power BI can then show "last
successful run" per pipeline directly in the dashboard, which is a nice,
concrete demonstration of observability thinking beyond just alerting.
