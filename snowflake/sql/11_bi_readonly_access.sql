-- FinPulse — Power BI Read-Only Access
-- Separate from finpulse_dbt_role: BI tools should only ever read the
-- Gold/analytics layer, never touch raw/staging or have write access.

USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS finpulse_bi_role;

GRANT USAGE ON WAREHOUSE finpulse_wh TO ROLE finpulse_bi_role;
GRANT USAGE ON DATABASE finpulse_db TO ROLE finpulse_bi_role;
GRANT USAGE ON SCHEMA finpulse_db.analytics TO ROLE finpulse_bi_role;
GRANT SELECT ON ALL TABLES IN SCHEMA finpulse_db.analytics TO ROLE finpulse_bi_role;
GRANT SELECT ON FUTURE TABLES IN SCHEMA finpulse_db.analytics TO ROLE finpulse_bi_role;
-- Deliberately no grants on raw/staging schemas.

CREATE USER IF NOT EXISTS finpulse_bi_user
    PASSWORD = 'ChangeThisStrongPassword456!'
    DEFAULT_ROLE = finpulse_bi_role
    DEFAULT_WAREHOUSE = finpulse_wh
    MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE finpulse_bi_role TO USER finpulse_bi_user;
