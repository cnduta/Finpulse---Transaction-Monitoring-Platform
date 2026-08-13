-- Bronze: light typing only. No filtering, no dedup, no business rules.
-- Purpose is purely to make raw VARIANT data queryable as normal columns.

select
    raw_data:transaction_id::string      as transaction_id,
    raw_data:account_id::string          as account_id,
    raw_data:customer_name::string       as customer_name,
    raw_data:amount::float               as amount,
    raw_data:currency::string            as currency,
    raw_data:country::string             as country,
    raw_data:merchant::string            as merchant,
    raw_data:is_high_risk_country::boolean as is_high_risk_country,
    raw_data:event_timestamp::timestamp_ntz as event_timestamp,
    _loaded_at
from {{ source('raw', 'raw_transactions_streaming') }}
