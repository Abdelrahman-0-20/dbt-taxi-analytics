-- Incremental fact: first run loads everything, later runs only add rows with a
-- pickup_at newer than what {{ this }} already holds — never reprocessing history.
{{
    config(
        materialized = 'incremental',
        unique_key = 'trip_sk'
    )
}}

with trips as (
    select *
    from {{ ref('int_trips_clean') }}

    {% if is_incremental() %}
        where pickup_at > (select coalesce(max(pickup_at), timestamp '1900-01-01') from {{ this }})
    {% endif %}
)

select
    {{ dbt_utils.generate_surrogate_key([
        'pickup_at', 'dropoff_at', 'pickup_location_id', 'dropoff_location_id', 'fare_amount'
    ]) }} as trip_sk,
    pickup_at,
    dropoff_at,
    date_diff('second', pickup_at, dropoff_at) as duration_seconds,
    passenger_count,
    trip_distance,
    pickup_location_id,
    dropoff_location_id,
    payment_type_code,
    fare_amount,
    tip_amount,
    total_amount,
    current_timestamp as loaded_at
from trips
