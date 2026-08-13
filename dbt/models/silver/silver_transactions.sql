-- Silver: dedup, data quality filtering, business rule flags.
-- Incremental: on each run, only processes rows newer than what's already
-- in this table — this is where the "watermark" concept shows up again,
-- but implemented natively in dbt rather than a control table.

{{
    config(
        materialized='incremental',
        unique_key='transaction_id',
        on_schema_change='append_new_columns'
    )
}}

with source as (
    select * from {{ ref('bronze_transactions') }}

    {% if is_incremental() %}
    -- Only pull rows loaded since the last successful run of this model
    where _loaded_at > (select coalesce(max(_loaded_at), '1900-01-01') from {{ this }})
    {% endif %}
),

deduped as (
    -- Guard against Event Hubs' at-least-once delivery producing duplicate events
    select *,
        row_number() over (
            partition by transaction_id
            order by _loaded_at desc
        ) as rn
    from source
),

cleaned as (
    select
        transaction_id,
        account_id,
        customer_name,
        amount,
        currency,
        country,
        merchant,
        is_high_risk_country,
        event_timestamp,
        _loaded_at,
        -- Simple rules-based flagging — NOT a production AML model.
        -- Documented explicitly as a limitation in the root README.
        case
            when amount > 10000 then true
            when is_high_risk_country then true
            else false
        end as is_flagged
    from deduped
    where rn = 1
      and amount > 0          -- basic sanity filter
      and transaction_id is not null
)

select * from cleaned
