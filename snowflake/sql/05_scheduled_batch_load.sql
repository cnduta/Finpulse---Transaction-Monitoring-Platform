-- FinPulse — Raw Table + Scheduled COPY INTO (batch path)
USE DATABASE finpulse_db;
USE SCHEMA raw;

CREATE TABLE IF NOT EXISTS raw_fx_rates_batch (
    raw_data VARIANT,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Unlike streaming (event-driven via Snowpipe), batch data doesn't need
-- near-real-time pickup — a scheduled Task running COPY INTO is simpler
-- and cheaper for a low-frequency source like daily FX rates.
-- COPY INTO is naturally idempotent here: Snowflake tracks which files it
-- has already loaded per stage and skips them on rerun (unless FORCE=TRUE),
-- which nicely mirrors the watermarking concept on the Azure/ADF side.
CREATE TASK IF NOT EXISTS task_load_fx_rates_batch
    WAREHOUSE = finpulse_wh
    SCHEDULE = 'USING CRON 0 6 * * * UTC'  -- daily at 06:00 UTC
    AS
    COPY INTO raw_fx_rates_batch (raw_data)
    FROM @stg_bronze_batch/fx_rates/
    FILE_FORMAT = json_format;

-- Tasks are created suspended by default — must explicitly resume:
ALTER TASK task_load_fx_rates_batch RESUME;

-- Check task run history later with:
-- SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME => 'task_load_fx_rates_batch'));
