with customer_order_history as (
    select *
    from {{ ref('int_customer_order_history') }}
),

orders_enriched as (
    select *
    from {{ ref('int_orders_enriched') }}
),

customer_history as (
    select
        customer_unique_id,
        min(order_purchase_date) as first_order_date,
        max(order_purchase_date) as latest_order_date,
        count(*) as lifetime_orders
    from customer_order_history
    group by 1
),

latest_customer_attributes as (
    select
        customer_unique_id,
        customer_city,
        customer_state,
        row_number() over (
            partition by customer_unique_id
            order by order_purchase_timestamp desc
        ) as customer_rank
    from orders_enriched
),

final as (
    select
        history.customer_unique_id,
        attributes.customer_city,
        attributes.customer_state,
        history.first_order_date,
        history.latest_order_date,
        history.lifetime_orders
    from customer_history as history
    left join latest_customer_attributes as attributes
        on history.customer_unique_id = attributes.customer_unique_id
       and attributes.customer_rank = 1
)

select *
from final
