{{
    config(
        partition_by={
            "field": "order_purchase_month_start",
            "data_type": "date",
            "granularity": "month",
        }
    )
}}

with fct_order_items as (
    select *
    from {{ ref('fct_order_items') }}
),

dim_products as (
    select *
    from {{ ref('dim_products') }}
),

fct_orders as (
    select *
    from {{ ref('fct_orders') }}
),

category_orders as (
    select
        items.order_purchase_month_start,
        coalesce(products.product_category_name_english, 'unknown') as category_name,
        items.order_id,
        sum(items.item_revenue) as category_revenue,
        count(*) as category_items_sold
    from fct_order_items as items
    left join dim_products as products
        on items.product_id = products.product_id
    group by 1, 2, 3
),

final as (
    select
        category_orders.order_purchase_month_start,
        category_orders.category_name,
        sum(category_orders.category_revenue) as category_revenue,
        count(distinct category_orders.order_id) as category_orders,
        sum(category_orders.category_items_sold) as category_items_sold,
        avg(
            case
                when orders.has_single_item_single_review then orders.average_review_score
            end
        ) as average_review_score,
        safe_divide(
            countif(orders.has_single_item_single_review and orders.has_order_low_review),
            countif(orders.has_single_item_single_review)
        ) as low_review_rate,
        safe_divide(countif(orders.is_delayed), countif(orders.is_delivered)) as delayed_order_rate
    from category_orders
    inner join fct_orders as orders
        on category_orders.order_id = orders.order_id
    group by 1, 2
)

select *
from final
