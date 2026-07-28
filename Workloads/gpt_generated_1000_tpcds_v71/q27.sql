WITH sales_agg AS (
  SELECT
    p.p_promo_id,
    p.p_promo_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_quantity) AS total_qty
  FROM tpcds.promotion p
  JOIN tpcds.web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
  WHERE p.p_discount_active = 'N'
    AND p.p_channel_tv = 'Y'
    AND ws.ws_ext_sales_price > 500
    AND ws.ws_quantity >= 5
    AND ws.ws_net_paid_inc_tax BETWEEN 1000 AND 5000
    AND ws.ws_ship_mode_sk IN (1, 2, 3)
  GROUP BY p.p_promo_id, p.p_promo_name
  HAVING SUM(ws.ws_ext_sales_price) > 5000
),
sales_ranked AS (
  SELECT
    p_promo_id,
    p_promo_name,
    total_sales AS metric_value,
    total_qty AS secondary_metric,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_sales DESC) AS metric_rank,
    'sales' AS metric_type
  FROM sales_agg
),
quantity_agg AS (
  SELECT
    p.p_promo_id,
    p.p_promo_name,
    SUM(ws.ws_quantity) AS total_qty,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
  FROM tpcds.promotion p
  JOIN tpcds.web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
  WHERE p.p_discount_active = 'N'
    AND p.p_channel_tv = 'N'
    AND ws.ws_ext_sales_price > 800
    AND ws.ws_quantity BETWEEN 10 AND 100
    AND ws.ws_net_paid_inc_tax < 3000
    AND ws.ws_ship_mode_sk NOT IN (4, 5)
  GROUP BY p.p_promo_id, p.p_promo_name
  HAVING SUM(ws.ws_quantity) > 200
),
quantity_ranked AS (
  SELECT
    p_promo_id,
    p_promo_name,
    total_qty AS metric_value,
    distinct_orders AS secondary_metric,
    DENSE_RANK() OVER (PARTITION BY p_promo_id ORDER BY total_qty DESC) AS metric_rank,
    'quantity' AS metric_type
  FROM quantity_agg
)
SELECT
  p_promo_id,
  p_promo_name,
  metric_value,
  metric_type,
  metric_rank,
  secondary_metric
FROM sales_ranked
UNION ALL
SELECT
  p_promo_id,
  p_promo_name,
  metric_value,
  metric_type,
  metric_rank,
  secondary_metric
FROM quantity_ranked
ORDER BY metric_value DESC
LIMIT 100
