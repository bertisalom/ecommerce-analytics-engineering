{{
    config(
        partition_by={
            "field": "order_purchase_date",
            "data_type": "date",
            "granularity": "day",
        }
    )
}}

with orders as (
    select *
    from {{ ref('stg_orders') }}
),

customers as (
    select *
    from {{ ref('stg_customers') }}
),

order_items as (
    select *
    from {{ ref('stg_order_items') }}
),

reviews as (
    select *
    from {{ ref('stg_reviews') }}
),

order_item_metrics as (
    select
        order_id,
        sum(price) as order_item_revenue,
        sum(freight_value) as order_freight_revenue,
        sum(item_revenue) as order_total_revenue,
        count(*) as item_count
    from order_items
    group by 1
),

review_metrics as (
    select
        order_id,
        count(*) as review_count,
        avg(review_score) as average_review_score,
        max(cast(is_low_review as int64)) = 1 as has_order_low_review
    from reviews
    group by 1
),

final as (
    select
        orders.order_id,
        orders.customer_id,
        customers.customer_unique_id,
        customers.customer_city,
        customers.customer_state,
        orders.order_status,
        orders.order_purchase_timestamp,
        orders.order_purchase_date,
        orders.order_purchase_month_start,
        orders.order_approved_at,
        orders.order_delivered_carrier_date,
        orders.order_delivered_customer_date,
        orders.order_estimated_delivery_date,
        orders.is_delivered,
        orders.is_canceled,
        orders.delivery_days,
        orders.estimated_delivery_days,
        orders.delivery_delay_days,
        orders.is_delayed,
        coalesce(items.order_item_revenue, 0) as order_item_revenue,
        coalesce(items.order_freight_revenue, 0) as order_freight_revenue,
        coalesce(items.order_total_revenue, 0) as order_total_revenue,
        coalesce(items.item_count, 0) as item_count,
        coalesce(reviews.review_count, 0) as review_count,
        reviews.average_review_score,
        coalesce(reviews.review_count, 0) > 0 as has_review,
        coalesce(reviews.has_order_low_review, false) as has_order_low_review,
        -- Review-based category metrics rely on review_count matching item_count,
        -- because the source does not map reviews directly to order items.
        coalesce(reviews.review_count, 0) = coalesce(items.item_count, 0) as has_matching_review_item_count
    from orders
    left join customers
        on orders.customer_id = customers.customer_id
    left join order_item_metrics as items
        on orders.order_id = items.order_id
    left join review_metrics as reviews
        on orders.order_id = reviews.order_id
)

select *
from final
