{{
    config(
        partition_by={
            "field": "order_purchase_month_start",
            "data_type": "date",
            "granularity": "day",
        }
    )
}}

with dim_customers as (
    select *
    from {{ ref('dim_customers') }}
),

fct_orders as (
    select *
    from {{ ref('fct_orders') }}
),

base as (
    select
        orders.order_purchase_month_start,
        case
            when date_trunc(customers.first_order_date, month) = orders.order_purchase_month_start then 'new_customer'
            else 'returning_customer'
        end as customer_segment,
        orders.customer_unique_id,
        orders.order_id,
        orders.order_total_revenue,
        orders.average_review_score,
        orders.is_delayed
    from fct_orders as orders
    inner join dim_customers as customers
        on orders.customer_unique_id = customers.customer_unique_id
),

final as (
    select
        order_purchase_month_start,
        customer_segment,
        count(distinct customer_unique_id) as customers,
        count(distinct order_id) as orders,
        sum(order_total_revenue) as revenue,
        avg(order_total_revenue) as average_order_value,
        safe_divide(sum(order_total_revenue), count(distinct customer_unique_id)) as average_revenue_per_customer,
        avg(average_review_score) as average_review_score,
        safe_divide(countif(is_delayed), count(*)) as delayed_order_rate
    from base
    group by 1, 2
)

select *
from final
