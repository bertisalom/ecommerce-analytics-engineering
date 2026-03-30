with source_data as (
    select *
    from {{ source('raw', 'reviews') }}
),

transformed as (
    select
        review_id,
        order_id,
        review_score,
        review_creation_date,
        review_answer_timestamp,
        review_score <= 2 as is_low_review
    from source_data
    {{ deduplicate_latest_ingestion('review_id') }}
)

select *
from transformed
