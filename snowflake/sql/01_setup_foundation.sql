-- FinPulse — Snowflake Foundation Setup
-- Run as ACCOUNTADMIN (or a role with CREATE DATABASE/WAREHOUSE privileges)

CREATE WAREHOUSE IF NOT EXISTS finpulse_wh
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS finpulse_db;

USE DATABASE finpulse_db;

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS analytics;

-- Dedicated role for dbt Cloud — least privilege, not ACCOUNTADMIN
CREATE ROLE IF NOT EXISTS finpulse_dbt_role;

GRANT USAGE ON WAREHOUSE finpulse_wh TO ROLE finpulse_dbt_role;
GRANT USAGE ON DATABASE finpulse_db TO ROLE finpulse_dbt_role;
GRANT ALL ON SCHEMA finpulse_db.raw TO ROLE finpulse_dbt_role;
GRANT ALL ON SCHEMA finpulse_db.staging TO ROLE finpulse_dbt_role;
GRANT ALL ON SCHEMA finpulse_db.analytics TO ROLE finpulse_dbt_role;

-- Service user for dbt Cloud (password set separately, not committed here)
CREATE USER IF NOT EXISTS finpulse_dbt_user
    DEFAULT_ROLE = finpulse_dbt_role
    DEFAULT_WAREHOUSE = finpulse_wh
    MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE finpulse_dbt_role TO USER finpulse_dbt_user;
