WITH source AS (
    SELECT * FROM {{ source('raw_olist', 'order_payments') }}
),

cleaned AS (
    SELECT
        CAST(order_id AS STRING) AS order_id,
        CAST(payment_sequential AS INT64) AS payment_sequential,
        CAST(
            TRIM(LOWER(payment_type)) AS STRING
        ) AS payment_type,
        SAFE_CAST(payment_installments AS INT64) AS payment_installments,
        SAFE_CAST(payment_value AS NUMERIC) AS payment_value
    FROM source
)

SELECT * FROM cleaned