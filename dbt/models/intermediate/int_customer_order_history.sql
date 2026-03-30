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

base as (
    select
        order_id,
        customer_unique_id,
        order_purchase_date,
        order_purchase_month_start,
        order_total_revenue,
        row_number() over (
            partition by customer_unique_id
            order by order_purchase_timestamp
        ) as customer_order_number
    from orders_enriched
),

final as (
    select
        order_id,
        customer_unique_id,
        order_purchase_date,
        order_purchase_month_start,
        order_total_revenue,
        customer_order_number,
        customer_order_number = 1 as is_first_order,
        customer_order_number > 1 as is_repeat_order
    from base
)

select *
from final
