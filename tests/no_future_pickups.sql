-- Singular test: no trip may claim a pickup timestamp in the future.
select *
from {{ ref('fct_trips') }}
where pickup_at >= current_timestamp
