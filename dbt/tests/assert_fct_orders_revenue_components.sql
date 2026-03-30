select *
from {{ ref('fct_orders') }}
where order_total_revenue != order_item_revenue + order_freight_revenue
