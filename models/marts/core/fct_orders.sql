-- Base order info
WITH initial_order_info AS (
  SELECT
    o.order_id,
    c.customer_unique_id,
    CONCAT('BR-', c.customer_state) AS customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    CASE 
      WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL 
      THEN TIMESTAMP_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, DAY)
      ELSE NULL 
    END AS delivery_lead_time_days
  FROM {{ ref('stg__orders') }} o
  JOIN {{ ref('stg__customers') }} c
    ON o.customer_id = c.customer_id
),

order_items_aggregated AS (
  SELECT
    order_id,
    COUNT(*) AS item_count,
    SUM(price) AS total_item_cost_brl,
    SUM(freight_value) AS total_freight_cost_brl
  FROM {{ ref('stg__order_items') }}
  GROUP BY order_id
),

-- Order payments info
order_payments_ranked AS (
  SELECT
    order_id,
    payment_type,
    payment_value,
    ROW_NUMBER() OVER (
      PARTITION BY order_id
      ORDER BY payment_value desc
    ) AS payment_rank
  FROM {{ ref('stg__order_payments') }}
),

primary_payment_type AS (
  SELECT
    order_id,
    payment_type AS primary_payment_type,
    payment_value
  FROM order_payments_ranked
  WHERE payment_rank = 1
),

payments_aggregated AS (
  SELECT
    a.order_id,
    SUM(a.payment_value) AS total_order_value_brl,
    p.primary_payment_type
  FROM {{ ref('stg__order_payments') }} a
  JOIN primary_payment_type p
    ON a.order_id = p.order_id
  GROUP BY order_id, p.primary_payment_type
)

SELECT
  i.order_id,
  i.customer_unique_id,
  i.customer_state,
  i.order_status,
  i.order_purchase_timestamp,
  i.order_delivered_customer_date,
  i.order_estimated_delivery_date,
  i.delivery_lead_time_days,

  COALESCE(items.item_count, 0) AS total_item_quantity,
  COALESCE(items.total_item_cost_brl, 0) AS total_item_cost_brl,
  COALESCE(items.total_freight_cost_brl, 0) AS total_freight_cost_brl,

  COALESCE(pay.total_order_value_brl, 0) AS total_order_value_brl,
  COALESCE(pay.primary_payment_type, 'unassigned') AS primary_payment_type,

  r.review_score 
FROM initial_order_info i
LEFT JOIN order_items_aggregated items
  ON i.order_id = items.order_id
LEFT JOIN payments_aggregated pay
  ON i.order_id = pay.order_id
LEFT JOIN {{ ref('stg__order_reviews') }} r
  ON i.order_id = r.order_id