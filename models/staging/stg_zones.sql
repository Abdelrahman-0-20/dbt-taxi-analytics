select
    cast(locationid as integer) as location_id,   -- source column is "LocationID"
    borough,
    zone as zone_name,
    service_zone
from read_csv('{{ var("zones_path") }}')
