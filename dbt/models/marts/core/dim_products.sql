with products as (
    select *
    from {{ ref('stg_products') }}
),

category_translation as (
    select *
    from {{ ref('stg_category_translation') }}
),

final as (
    select
        products.product_id,
        category_translation.product_category_name_english
    from products
    left join category_translation
        on products.product_category_name = category_translation.product_category_name
)

select *
from final
