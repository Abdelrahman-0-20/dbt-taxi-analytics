-- Cleaning rules live in SQL, thresholds come from dbt vars (dbt_project.yml).
-- Ephemeral: inlined as a CTE wherever it is referenced — no table is written.
with cleaned as (
    select *
    from {{ ref('stg_trips') }}
    where dropoff_at > pickup_at
      and pickup_at >= timestamp '2024-01-01'
      and pickup_at < timestamp '2024-02-01'          -- half-open window: boundaries never double-count
      and fare_amount between 0.0 and {{ var('max_fare') }}
      and trip_distance between 0.0 and {{ var('max_distance') }}
      and passenger_count between {{ var('min_passengers') }} and {{ var('max_passengers') }}
      and payment_type_code between 0 and 6
)

select *
from cleaned
qualify row_number() over (
    partition by pickup_at, dropoff_at, pickup_location_id, dropoff_location_id, fare_amount
    order by trip_distance
) = 1
