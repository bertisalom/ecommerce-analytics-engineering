with source_data as (
    select *
    from {{ source('raw', 'customers') }}
),

transformed as (
    select
        customer_id,
        customer_unique_id,
        customer_city,
        customer_state
    from source_data
    {{ deduplicate_latest_ingestion('customer_id') }}
)

select *
from transformed

