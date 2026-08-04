WITH
  small_dates AS (
    SELECT d_date
    FROM date_dim
    WHERE d_year = 2000
      AND d_month_seq BETWEEN 1200 AND 1202
  ),
  sales_metrics AS (
    SELECT
      w.w_warehouse_name,
      'sales' AS metric_type,
      SUM(cs.cs_ext_sales_price) AS metric_value,
      CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'high' ELSE 'normal' END AS category
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE p.p_channel_dmail = 'Y'
      AND d.d_year = 2000
    GROUP BY w.w_warehouse_name
    HAVING SUM(cs.cs_ext_sales_price) > 50000
  ),
  inventory_metrics AS (
    SELECT
      w.w_warehouse_name,
      'inventory' AS metric_type,
      SUM(i.inv_quantity_on_hand) AS metric_value,
      CASE WHEN SUM(i.inv_quantity_on_hand) > 10000 THEN 'high_stock' ELSE 'low_stock' END AS category
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY w.w_warehouse_name
    HAVING SUM(i.inv_quantity_on_hand) > 2000
  ),
  combined_metrics AS (
    SELECT * FROM sales_metrics
    UNION ALL
    SELECT * FROM inventory_metrics
  )
SELECT
  sd.d_date,
  cm.w_warehouse_name,
  cm.metric_type,
  cm.metric_value,
  cm.category
FROM small_dates sd
CROSS JOIN combined_metrics cm
ORDER BY sd.d_date DESC,
         cm.metric_value DESC
LIMIT 100
