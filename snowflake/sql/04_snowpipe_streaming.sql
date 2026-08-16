-- FinPulse — Raw Table + Scheduled Snowpipe Refresh (streaming path)
--
-- DESIGN NOTE: True event-driven AUTO_INGEST on Azure requires an
-- Event Grid System Topic + Storage Queue + Snowflake NOTIFICATION
-- INTEGRATION. That was evaluated and deliberately deferred in favor of
-- a scheduled pipe REFRESH via a Snowflake Task — a legitimate,
-- commonly-used "near-real-time" pattern, simpler to operate, at the
-- cost of true sub-minute event-driven latency. Revisit Event Grid
-- integration if sub-5-minute freshness becomes a real requirement.

USE DATABASE finpulse_db;
USE SCHEMA raw;

CREATE TABLE IF NOT EXISTS raw_transactions_streaming (
    raw_data VARIANT,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE PIPE IF NOT EXISTS pipe_transactions_streaming
    AUTO_INGEST = FALSE
    AS
    COPY INTO raw_transactions_streaming (raw_data)
    FROM @stg_raw_streaming
    FILE_FORMAT = avro_format;

-- Refreshes every 5 min, matching Event Hubs Capture's flush interval
CREATE TASK IF NOT EXISTS task_refresh_streaming_pipe
    WAREHOUSE = finpulse_wh
    SCHEDULE = '5 MINUTE'
    AS
    ALTER PIPE pipe_transactions_streaming REFRESH;

ALTER TASK task_refresh_streaming_pipe RESUME;
