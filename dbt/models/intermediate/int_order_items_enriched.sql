{{
    config(
        partition_by={
            "field": "order_purchase_date",
            "data_type": "date",
            "granularity": "day",
        }
    )
}}

with order_items as (
    select *
    from {{ ref('stg_order_items') }}
),

orders as (
    select *
    from {{ ref('stg_orders') }}
),

products as (
    select *
    from {{ ref('stg_products') }}
),

category_translation as (
    select *
    from {{ ref('stg_category_translation') }}
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
        orders.order_purchase_timestamp,
        orders.order_purchase_date,
        orders.order_purchase_month_start,
        products.product_category_name,
        translations.product_category_name_english
    from order_items as items
    inner join orders
        on items.order_id = orders.order_id
    left join products
        on items.product_id = products.product_id
    left join category_translation as translations
        on products.product_category_name = translations.product_category_name
)

select *
from final
