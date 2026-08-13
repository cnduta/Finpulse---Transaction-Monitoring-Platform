-- SCD Type 2 via dbt snapshots. Snapshots are dbt's built-in mechanism for
-- tracking how a row changes over time — exactly what SCD Type 2 needs.
--
-- Run with: dbt snapshot
-- This creates/maintains a table with dbt-managed columns:
--   dbt_valid_from, dbt_valid_to, dbt_scd_id
-- A NULL dbt_valid_to means "this is the current version of the row."

{% snapshot snap_accounts %}

{{
    config(
        target_schema='analytics',
        unique_key='account_id',
        strategy='check',
        check_cols=['customer_name', 'country'],
    )
}}

-- Sourced from staging.accounts_current, which is kept up to date by the
-- Snowflake Stream + Task CDC pipeline (see snowflake/sql/08-10).
-- This is the real integration point between native Snowflake CDC and
-- dbt's SCD Type 2 tracking.
select
    account_id,
    customer_name,
    country
from {{ source('staging', 'accounts_current') }}

{% endsnapshot %}
