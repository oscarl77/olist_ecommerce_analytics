WITH source AS (
    SELECT * FROM {{ source('raw_olist', 'product_category_name_translation') }}
),

cleaned_and_renamed AS (
    SELECT
        LOWER(TRIM(string_field_0)) AS product_category_name_pt,
        LOWER(TRIM(string_field_1)) AS product_category_name_en
    FROM source
    -- Filter out the CSV header row that BigQuery loaded as data
    WHERE LOWER(TRIM(string_field_0)) != 'product_category_name'
      AND string_field_0 IS NOT NULL
)

SELECT * FROM cleaned_and_renamed