{{
    config(
        partition_by={
            "field": "order_purchase_month_start",
            "data_type": "date",
            "granularity": "day",
        }
    )
}}

with fct_orders as (
    select *
    from {{ ref('fct_orders') }}
),

base as (
    select
        order_purchase_month_start,
        case
            when not is_delivered then 'not_delivered'
            when delivery_delay_days < 0 then 'early'
            when delivery_delay_days = 0 then 'on_time'
            when delivery_delay_days between 1 and 3 then 'slightly_delayed'
            else 'heavily_delayed'
        end as delivery_bucket,
        average_review_score,
        has_order_low_review,
        is_delivered
    from fct_orders
),

final as (
    select
        order_purchase_month_start,
        delivery_bucket,
        count(*) as orders,
        avg(average_review_score) as average_review_score,
        safe_divide(countif(has_order_low_review), count(*)) as low_review_rate
    from base
    group by 1, 2
)

select *
from final
