-- FinPulse — Phase 3 Verification
USE DATABASE finpulse_db;
USE SCHEMA raw;

-- Row counts
SELECT COUNT(*) AS streaming_row_count FROM raw_transactions_streaming;
SELECT COUNT(*) AS batch_row_count FROM raw_fx_rates_batch;

-- Peek at a raw streaming record's structure (VARIANT/JSON navigation)
SELECT raw_data:transaction_id::STRING AS transaction_id,
       raw_data:amount::FLOAT AS amount,
       raw_data:currency::STRING AS currency,
       raw_data:country::STRING AS country,
       _loaded_at
FROM raw_transactions_streaming
LIMIT 10;

-- Confirm Snowpipe is actually running (not just created)
SELECT SYSTEM$PIPE_STATUS('pipe_transactions_streaming');
