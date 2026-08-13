-- FinPulse — Raw Tables + Snowpipe (streaming path)
USE DATABASE finpulse_db;
USE SCHEMA raw;

-- Raw landing table for streaming transactions.
-- VARIANT column keeps ingestion simple/robust — we parse structure in dbt (Bronze->Silver),
-- not here. This is a deliberate "land it raw, transform downstream" choice worth explaining.
CREATE TABLE IF NOT EXISTS raw_transactions_streaming (
    raw_data VARIANT,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Snowpipe: auto-ingests new files as they land in the stage.
-- AUTO_INGEST relies on an event notification from Azure (Event Grid) telling
-- Snowflake "a new file arrived" — this is the near-real-time path.
CREATE PIPE IF NOT EXISTS pipe_transactions_streaming
    AUTO_INGEST = TRUE
    AS
    COPY INTO raw_transactions_streaming (raw_data)
    FROM @stg_raw_streaming
    FILE_FORMAT = avro_format;

-- After creating this, get the notification integration details:
SHOW PIPES LIKE 'pipe_transactions_streaming';
-- Look for "notification_channel" in the output — you'll wire this to an
-- Azure Event Grid subscription on the storage account so new blobs trigger
-- Snowpipe automatically. (Documented as a manual one-time Azure Portal step
-- in docs/snowpipe_event_grid_setup.md — see next file.)
