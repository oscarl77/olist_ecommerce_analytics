SELECT
    CAST(customer_id AS STRING) AS customer_id,
    CAST(customer_unique_id AS STRING) AS customer_unique_id,
    SAFE_CAST(customer_zip_code_prefix AS STRING) AS customer_zip_code_prefix,
    CAST(customer_city AS STRING) AS customer_city,
    CAST(customer_state AS STRING) AS customer_state
FROM {{ source('raw_olist', 'customers') }}