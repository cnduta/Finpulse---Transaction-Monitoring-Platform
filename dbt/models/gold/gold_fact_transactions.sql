-- Gold: fact table for Power BI. Joins Silver transactions to the current
-- version of each account (dbt_valid_to IS NULL = current row in SCD2).

select
    t.transaction_id,
    t.account_id,
    a.customer_name,
    t.amount,
    t.currency,
    t.country,
    t.merchant,
    t.is_flagged,
    t.event_timestamp,
    a.dbt_valid_from as account_version_valid_from
from {{ ref('silver_transactions') }} t
left join {{ ref('snap_accounts') }} a
    on t.account_id = a.account_id
    and a.dbt_valid_to is null
