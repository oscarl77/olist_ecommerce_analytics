WITH order_level_delays AS (
  SELECT
    o.order_id,
    c.customer_state,
    DATE_TRUNC(o.order_purchase_timestamp, MONTH) AS order_purchase_month,
    DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_purchase_timestamp), DAY) AS transit_days,
    DATE_DIFF(DATE(o.order_estimated_delivery_date), DATE(o.order_purchase_timestamp), DAY) AS estimated_transit_days,
    DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_estimated_delivery_date), DAY) AS delay_days,
    CASE
      WHEN DATE(o.order_delivered_customer_date) <= DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0
    END AS is_on_time
  FROM {{ ref("fct_orders") }} o
  JOIN {{ ref("dim_customers") }} c
    ON o.customer_unique_id = c.customer_unique_id
  WHERE order_status = 'delivered'
    AND order_purchase_timestamp >= '2017-01-01'
    AND order_delivered_customer_date IS NOT NULL
)

SELECT
  order_purchase_month,
  customer_state,
  COUNT(order_id) AS total_orders_delivered,
  ROUND(AVG(transit_days), 1) AS avg_transit_days,
  ROUND(AVG(estimated_transit_days), 1) AS avg_estimated_transit_days,
  ROUND(SUM(is_on_time) / COUNT(order_id) * 100, 2) AS on_time_delivery_rate_pct,
  ROUND(AVG(CASE WHEN is_on_time = 0 THEN delay_days END), 1) AS avg_delay_days_late_orders
FROM order_level_delays
GROUP BY 1, 2
ORDER BY order_purchase_month ASC, customer_state ASC