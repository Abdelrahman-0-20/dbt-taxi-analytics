-- Raw parquet -> typed columns. No filtering here: staging mirrors the source.
-- dbt-duckdb reads the file as a relation, so no loader step is required.
select
    vendorid as vendor_id,   -- source column is "VendorID"; DuckDB folds case but not underscores
    tpep_pickup_datetime as pickup_at,
    tpep_dropoff_datetime as dropoff_at,
    cast(passenger_count as integer) as passenger_count,
    cast(trip_distance as double) as trip_distance,
    cast(pulocationid as integer) as pickup_location_id,
    cast(dolocationid as integer) as dropoff_location_id,
    cast(payment_type as integer) as payment_type_code,
    cast(fare_amount as double) as fare_amount,
    cast(tip_amount as double) as tip_amount,
    cast(total_amount as double) as total_amount
from read_parquet('{{ var("trips_path") }}')
