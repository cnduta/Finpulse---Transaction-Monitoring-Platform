-- FinPulse — Snowflake Foundation Setup
-- Run as ACCOUNTADMIN (or a role with CREATE DATABASE/WAREHOUSE privileges)

-- Warehouse: X-Small is plenty for demo volumes.
-- AUTO_SUSPEND=60 means it suspends after 60s idle — you're billed per-second
-- while running, effectively pennies for a project like this.
CREATE WAREHOUSE IF NOT EXISTS finpulse_wh
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS finpulse_db;

USE DATABASE finpulse_db;

-- Medallion-aligned schemas
CREATE SCHEMA IF NOT EXISTS raw;        -- Bronze: landed data, minimal transformation
CREATE SCHEMA IF NOT EXISTS staging;    -- Silver: cleaned, deduped, business rules applied
CREATE SCHEMA IF NOT EXISTS analytics;  -- Gold: dimensional model for Power BI

-- Dedicated role for dbt Cloud — least privilege, not using ACCOUNTADMIN
-- for day-to-day transformation work
CREATE ROLE IF NOT EXISTS finpulse_dbt_role;

GRANT USAGE ON WAREHOUSE finpulse_wh TO ROLE finpulse_dbt_role;
GRANT USAGE ON DATABASE finpulse_db TO ROLE finpulse_dbt_role;
GRANT ALL ON SCHEMA finpulse_db.raw TO ROLE finpulse_dbt_role;
GRANT ALL ON SCHEMA finpulse_db.staging TO ROLE finpulse_dbt_role;
GRANT ALL ON SCHEMA finpulse_db.analytics TO ROLE finpulse_dbt_role;

-- Dedicated service user for dbt Cloud (swap password for a strong one,
-- or better: use key-pair auth — see dbt Cloud connection docs)
CREATE USER IF NOT EXISTS finpulse_dbt_user
    PASSWORD = 'ChangeThisStrongPassword123!'
    DEFAULT_ROLE = finpulse_dbt_role
    DEFAULT_WAREHOUSE = finpulse_wh
    MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE finpulse_dbt_role TO USER finpulse_dbt_user;
