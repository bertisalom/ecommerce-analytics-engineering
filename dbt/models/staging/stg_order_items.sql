with source_data as (
    select *
    from {{ source('raw', 'order_items') }}
),

transformed as (
    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        cast(price as numeric) as price,
        cast(freight_value as numeric) as freight_value,
        cast(price as numeric) + cast(freight_value as numeric) as item_revenue
    from source_data
    {{ deduplicate_latest_ingestion(['order_id', 'order_item_id']) }}
)

select *
from transformed

