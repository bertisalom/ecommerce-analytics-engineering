{{
    config(
        partition_by={
            "field": "order_purchase_date",
            "data_type": "date",
            "granularity": "day",
        }
    )
}}

with orders_enriched as (
    select *
    from {{ ref('int_orders_enriched') }}
),

final as (
    select
        order_id,
        customer_unique_id,
        customer_city,
        customer_state,
        order_status,
        order_purchase_timestamp,
        order_purchase_date,
        order_purchase_month_start,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        is_delivered,
        is_canceled,
        delivery_days,
        estimated_delivery_days,
        delivery_delay_days,
        is_delayed,
        order_item_revenue,
        order_freight_revenue,
        order_total_revenue,
        item_count,
        review_count,
        average_review_score,
        has_review,
        has_order_low_review,
        has_single_item_single_review
    from orders_enriched
)

select *
from final
