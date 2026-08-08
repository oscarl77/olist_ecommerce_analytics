WITH source AS (
    SELECT * FROM {{ source('raw_olist', 'order_items') }}
),

cleaned AS (
    SELECT
        CAST(order_id AS STRING) AS order_id,
        CAST(order_item_id AS STRING) AS order_item_id,
        CAST(product_id AS STRING) AS product_id,
        CAST(seller_id AS STRING) AS seller_id,
        SAFE_CAST(shipping_limit_date AS TIMESTAMP) AS shipping_limit_date,
        SAFE_CAST(price AS NUMERIC) AS price,
        SAFE_CAST(freight_value AS NUMERIC) AS freight_value
    FROM source
)

SELECT * FROM cleaned