-- FinPulse — Watermark Control Table
-- Tracks the last successfully loaded timestamp per source, so incremental
-- ADF pipeline runs only pull new/changed records.

CREATE TABLE dbo.watermark_control (
    source_name       VARCHAR(100) NOT NULL PRIMARY KEY,
    last_loaded_value VARCHAR(100) NOT NULL,   -- stored as string; cast as needed per source
    last_updated_at   DATETIME2 DEFAULT SYSUTCDATETIME(),
    last_run_status   VARCHAR(20) DEFAULT 'PENDING'  -- SUCCESS / FAILED / PENDING
);

-- Seed an initial watermark for our reference-data batch source
-- (e.g. exchange rates API). Pipeline will pull anything newer than this.
INSERT INTO dbo.watermark_control (source_name, last_loaded_value)
VALUES ('fx_rates_api', '1900-01-01T00:00:00Z');
