WITH order_level_delays AS (
  SELECT
    order_id,
    customer_state,
    DATE_TRUNC(order_purchase_timestamp, MONTH) AS order_purchase_month,
    delivery_lead_time_days,
    TIMESTAMP_DIFF(order_estimated_delivery_date, order_purchase_timestamp, DAY) AS estimated_transit_days,
    TIMESTAMP_DIFF(order_delivered_customer_date, order_estimated_delivery_date, DAY) AS delay_days,
    CASE
      WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0
    END AS is_late
  FROM {{ ref("fct_orders") }}
  WHERE order_status = 'delivered'
    AND order_purchase_timestamp >= '2017-01-01'
    AND order_delivered_customer_date IS NOT NULL
)

SELECT
  order_purchase_month,
  customer_state,
  COUNT(order_id) AS total_orders_delivered,
  ROUND(AVG(delivery_lead_time_days), 1) AS avg_delivery_lead_time_days,
  ROUND(AVG(estimated_transit_days), 1) AS avg_estimated_lead_time_days,
  ROUND(AVG(is_late) * 100, 2) AS late_delivery_rate_pct,
  ROUND(AVG(CASE WHEN is_late = 1 THEN delay_days END), 1) AS avg_delay_days_when_late
FROM order_level_delays
GROUP BY 1, 2
ORDER BY order_purchase_month ASC, customer_state ASC