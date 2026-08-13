# ADF Watermarking — Design Notes

## Pattern
`watermark_control` table (Azure SQL) stores the last successfully-loaded
value per source. Pipeline flow: Lookup watermark → Copy only new/changed
data → Stored Procedure advances watermark **only on success**. If Copy
fails, the watermark is untouched, so the next run safely retries rather
than skipping data.

## Known limitation (by design, documented not hidden)
The demo source (frankfurter.app FX rates API) doesn't support a
"records since X" query parameter — it always returns the latest full
snapshot. So this particular pipeline can't demonstrate "zero new rows
on a repeat run" the way a true CDC/timestamp-filtered source would.

To properly exercise the watermark's core guarantee — safe reruns after
failure, correct handling of late-arriving data — that's done against
the **Snowflake Streams (CDC)** path in Phase 5, and via the deliberate
late-record/failure injection exercises in Phase 10 (week-long
simulation), where we control the source data directly.

## Real-world equivalent
In a production job, the source would typically be a transactional
database or an API that supports `?modified_since=<timestamp>` or
`?updated_after=<id>` — the watermark value would filter the query
directly, and reruns with no new data would correctly return zero rows.
