-- FinPulse — Stream on accounts_master
-- A Stream is Snowflake's native CDC object: it tracks INSERT/UPDATE/DELETE
-- changes since the stream was last "consumed" (queried inside a DML
-- statement like MERGE/INSERT). It does NOT store history itself — it's a
-- pointer/offset over the table's changes, similar conceptually to a
-- Kafka consumer offset.

USE DATABASE finpulse_db;
USE SCHEMA raw;

CREATE STREAM IF NOT EXISTS stream_accounts_master
    ON TABLE accounts_master
    APPEND_ONLY = FALSE;  -- FALSE = also capture UPDATEs/DELETEs, not just inserts

-- Inspect what the stream currently sees (should be empty right after creation,
-- since it only tracks changes going forward)
SELECT * FROM stream_accounts_master;
