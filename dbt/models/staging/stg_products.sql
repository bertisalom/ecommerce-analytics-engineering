with source_data as (
    select *
    from {{ source('raw', 'products') }}
),

transformed as (
    select
        product_id,
        product_category_name
    from source_data
    {{ deduplicate_latest_ingestion('product_id') }}
)

select *
from transformed

