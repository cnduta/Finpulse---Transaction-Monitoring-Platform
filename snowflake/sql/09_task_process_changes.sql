-- FinPulse — Task: consume stream, merge into staging
-- Reading FROM a stream inside a DML statement (like this MERGE) is what
-- "consumes" it — after this runs, the stream's offset advances and
-- these same changes won't appear again on the next run. That's the key
-- mechanic to understand and be able to explain.

USE DATABASE finpulse_db;
USE SCHEMA staging;

CREATE TABLE IF NOT EXISTS accounts_current (
    account_id     VARCHAR(20) PRIMARY KEY,
    customer_name  VARCHAR(200),
    country        VARCHAR(50),
    updated_at     TIMESTAMP_NTZ
);

USE SCHEMA raw;

CREATE TASK IF NOT EXISTS task_process_account_changes
    WAREHOUSE = finpulse_wh
    SCHEDULE = '5 MINUTE'  -- checks for changes every 5 min; adjust as needed
    WHEN SYSTEM$STREAM_HAS_DATA('stream_accounts_master')  -- skip runs with nothing to do (cost control)
    AS
    MERGE INTO staging.accounts_current tgt
    USING (
        SELECT account_id, customer_name, country, updated_at, METADATA$ACTION as action
        FROM stream_accounts_master
        WHERE METADATA$ACTION = 'INSERT'  -- Streams represent updates as DELETE+INSERT pairs;
                                            -- taking the INSERT side gives us the new values
    ) src
    ON tgt.account_id = src.account_id
    WHEN MATCHED THEN UPDATE SET
        customer_name = src.customer_name,
        country = src.country,
        updated_at = src.updated_at
    WHEN NOT MATCHED THEN INSERT (account_id, customer_name, country, updated_at)
        VALUES (src.account_id, src.customer_name, src.country, src.updated_at);

ALTER TASK task_process_account_changes RESUME;
