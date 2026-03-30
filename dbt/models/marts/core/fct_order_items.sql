{{
    config(
        partition_by={
            "field": "order_purchase_date",
            "data_type": "date",
            "granularity": "day",
        }
    )
}}

with order_items_enriched as (
    select *
    from {{ ref('int_order_items_enriched') }}
),

dim_products as (
    select *
    from {{ ref('dim_products') }}
),

final as (
    select
        items.order_id,
        items.order_item_id,
        items.product_id,
        items.seller_id,
        items.shipping_limit_date,
        items.price,
        items.freight_value,
        items.item_revenue,
        items.order_purchase_timestamp,
        items.order_purchase_date,
        items.order_purchase_month_start,
        products.product_category_name_english
    from order_items_enriched as items
    left join dim_products as products
        on items.product_id = products.product_id
)

select *
from final
