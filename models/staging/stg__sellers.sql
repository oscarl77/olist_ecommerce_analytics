WITH source AS (
    SELECT * FROM {{ source('raw_olist', 'sellers') }}
),

cleaned AS (
    SELECT
        CAST(seller_id AS STRING) AS seller_id,
        SAFE_CAST(seller_zip_code_prefix AS STRING) AS seller_zip_code_prefix,
        SAFE_CAST(LOWER(TRIM(seller_city)) AS STRING) AS seller_city,
        SAFE_CAST(UPPER(TRIM(seller_state)) AS STRING) AS seller_state
    FROM source
)

SELECT * FROM cleaned