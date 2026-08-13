-- FinPulse — Accounts Master (simulated source system table)
-- In a real setup, this would be a CDC feed from a core banking system.
-- Here we simulate it directly with a mutable Snowflake table so we can
-- manually trigger UPDATEs to test the CDC pipeline end-to-end.

USE DATABASE finpulse_db;
USE SCHEMA raw;

CREATE TABLE IF NOT EXISTS accounts_master (
    account_id     VARCHAR(20) PRIMARY KEY,
    customer_name  VARCHAR(200),
    country        VARCHAR(50),
    updated_at     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Seed a few accounts (adjust account_ids to match ones your producer
-- actually generated, if you want the join to Gold to line up)
INSERT INTO accounts_master (account_id, customer_name, country) VALUES
    ('ACC10001', 'Jane Wanjiru', 'Kenya'),
    ('ACC10002', 'David Okafor', 'Nigeria'),
    ('ACC10003', 'Sarah Thompson', 'UK');
