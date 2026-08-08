WITH source AS (
    SELECT * FROM {{ source('raw_olist', 'order_reviews') }}
),

deduplicated_and_cleaned AS (
    SELECT
        CAST(review_id AS STRING) AS review_id,
        CAST(order_id AS STRING) AS order_id,
        SAFE_CAST(review_score AS INT64) AS review_score,
        LOWER(TRIM(review_comment_title)) AS review_comment_title,
        LOWER(TRIM(review_comment_message)) AS review_comment_message,
        SAFE_CAST(review_creation_date AS TIMESTAMP) AS review_creation_date,
        SAFE_CAST(review_answer_timestamp AS TIMESTAMP) AS review_answer_timestamp
    FROM source

    QUALIFY ROW_NUMBER() OVER(
        PARTITION BY order_id 
        ORDER BY SAFE_CAST(review_answer_timestamp AS TIMESTAMP) DESC
    ) = 1
)

SELECT * FROM deduplicated_and_cleaned