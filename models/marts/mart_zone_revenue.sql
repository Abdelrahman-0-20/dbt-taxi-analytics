select
    cast(f.pickup_at as date) as revenue_date,
    z.borough,
    z.zone_name,
    count(*) as trip_count,
    round(sum(f.fare_amount), 2) as total_fare
from {{ ref('fct_trips') }} as f
join {{ ref('dim_zones') }} as z
    on f.pickup_location_id = z.location_id
group by 1, 2, 3
