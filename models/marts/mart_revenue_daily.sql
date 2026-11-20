select
    cast(pickup_at as date) as revenue_date,
    count(*) as trip_count,
    round(sum(fare_amount), 2) as total_fare,
    round(sum(tip_amount), 2) as total_tip,
    round(avg(trip_distance), 2) as avg_distance,
    count(distinct pickup_location_id) as distinct_zones,
    current_timestamp as refreshed_at
from {{ ref('fct_trips') }}
group by 1
