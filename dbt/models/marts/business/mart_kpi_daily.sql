{{
    config(
        partition_by={
            "field": "order_purchase_date",
            "data_type": "date",
            "granularity": "day",
        }
    )
}}

with fct_orders as (
    select *
    from {{ ref('fct_orders') }}
),

final as (
    select
        order_purchase_date,
        count(*) as total_orders,
        countif(is_delivered) as delivered_orders,
        countif(is_canceled) as canceled_orders,
        sum(order_total_revenue) as gross_revenue,
        avg(order_total_revenue) as average_order_value,
        safe_divide(countif(is_delivered), count(*)) as delivery_success_rate,
        safe_divide(countif(is_canceled), count(*)) as cancellation_rate,
        avg(delivery_days) as average_delivery_days,
        safe_divide(countif(is_delayed), countif(is_delivered)) as delayed_order_rate,
        avg(average_review_score) as average_review_score
    from fct_orders
    group by 1
)

select *
from final
