-- Base customer order information
WITH customer_orders_aggregated AS (
  SELECT
    customer_unique_id,
    MIN(order_purchase_timestamp) AS first_order_timestamp,
    MAX(order_purchase_timestamp) AS most_recent_order_timestamp,
    COUNT(order_id) AS lifetime_orders,
    SUM(total_order_value_brl) AS lifetime_spend_brl
  FROM {{ ref('fct_orders') }}
  GROUP BY customer_unique_id
),

-- Customer metrics derived from order aggregation
derived_customer_metrics AS (
  SELECT
    customer_unique_id,
    first_order_timestamp,
    most_recent_order_timestamp,
    lifetime_orders,
    lifetime_spend_brl,
    SAFE_DIVIDE(lifetime_spend_brl, lifetime_orders) AS average_order_value_brl,
    DATE_DIFF(most_recent_order_timestamp, first_order_timestamp, DAY) AS tenure_days,
    (lifetime_orders > 1) AS is_repeat_customer
  FROM customer_orders_aggregated
),

-- Latest customer location information based on most recent order
latest_customer_locations AS (
  SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
  FROM {{ ref('stg__customers') }} c
  JOIN {{ ref('fct_orders') }} o
    ON c.customer_unique_id = o.customer_unique_id
  QUALIFY ROW_NUMBER() OVER (
      PARTITION BY c.customer_unique_id
      ORDER BY o.order_purchase_timestamp DESC
  ) = 1
)

SELECT
  m.customer_unique_id,
  l.customer_city,
  l.customer_state,
  m.first_order_timestamp,
  m.most_recent_order_timestamp,
  m.lifetime_orders,
  m.lifetime_spend_brl,
  m.average_order_value_brl,
  m.tenure_days,
  m.is_repeat_customer
FROM derived_customer_metrics m
LEFT JOIN latest_customer_locations l
  ON m.customer_unique_id = l.customer_unique_id
