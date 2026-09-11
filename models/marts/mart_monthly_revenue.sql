WITH monthly_metrics AS (
  SELECT
    DATE_TRUNC(order_purchase_timestamp, MONTH) AS order_purchase_month,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    ROUND(SUM(total_item_cost_brl), 2) AS gross_revenue_brl,
    ROUND(AVG(total_item_cost_brl), 2) AS avg_order_value_brl
  FROM {{  ref("fct_orders") }}
  WHERE order_status = 'delivered'
    AND order_purchase_timestamp >= '2017-01-01'
  GROUP BY 1   
)

SELECT
  order_purchase_month,
  total_orders,
  total_customers,
  gross_revenue_brl,
  avg_order_value_brl,
  ROUND(
    (gross_revenue_brl - LAG(gross_revenue_brl) OVER (ORDER BY order_purchase_month ASC))
    / NULLIF(LAG(gross_revenue_brl) OVER (ORDER BY order_purchase_month ASC), 0) * 100,
    2
  ) AS mom_revenue_growth_pct
FROM monthly_metrics
ORDER BY order_purchase_month ASC