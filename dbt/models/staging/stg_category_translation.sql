with source_data as (
    select *
    from {{ source ('raw', 'category_translation') }}
),

transformed as (
    select
        product_category_name,
        product_category_name_english
    from source_data
    {{ deduplicate_latest_ingestion('product_category_name') }}
)

select *
from transformed
