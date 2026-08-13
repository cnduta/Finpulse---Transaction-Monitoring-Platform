-- Gold: daily aggregates by country/currency, for the Power BI trend visuals.

select
    date_trunc('day', event_timestamp) as transaction_date,
    country,
    currency,
    count(*) as transaction_count,
    sum(amount) as total_amount,
    sum(case when is_flagged then 1 else 0 end) as flagged_count
from {{ ref('gold_fact_transactions') }}
group by 1, 2, 3
