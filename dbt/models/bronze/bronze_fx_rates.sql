select
    raw_data:base::string   as base_currency,
    raw_data:date::date     as rate_date,
    raw_data:rates::variant as rates_json,  -- kept as VARIANT; flattened in Silver
    _loaded_at
from {{ source('raw', 'raw_fx_rates_batch') }}
