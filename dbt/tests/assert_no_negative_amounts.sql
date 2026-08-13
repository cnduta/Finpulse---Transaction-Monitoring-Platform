-- Custom test: fails if any row is returned.
-- Amounts should always be positive after Silver's cleaning step —
-- this test exists as a safety net in case that logic ever regresses.

select *
from {{ ref('silver_transactions') }}
where amount <= 0
