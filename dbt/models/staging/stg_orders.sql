{{
    config(
        partition_by={
            "field": "order_purchase_date",
            "data_type": "date",
            "granularity": "day",
        }
    )
}}

with source_data as (
    select *
    from {{ source('raw', 'orders') }}
),

transformed as (
    select
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        date(order_purchase_timestamp) as order_purchase_date,
        date_trunc(date(order_purchase_timestamp), month) as order_purchase_month_start,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        order_status = 'delivered' as is_delivered,
        order_status = 'canceled' as is_canceled,
        date_diff(date(order_delivered_customer_date), date(order_purchase_timestamp), day) as delivery_days,
        date_diff(date(order_estimated_delivery_date), date(order_purchase_timestamp), day) as estimated_delivery_days,
        date_diff(date(order_delivered_customer_date), date(order_estimated_delivery_date), day) as delivery_delay_days,
        order_delivered_customer_date > order_estimated_delivery_date as is_delayed
    from source_data
    {{ deduplicate_latest_ingestion('order_id') }}
)

select *
from transformed
