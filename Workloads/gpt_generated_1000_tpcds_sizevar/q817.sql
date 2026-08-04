WITH sales_agg AS (
  SELECT
    w.w_warehouse_name AS warehouse_name,
    'sales' AS metric_type,
    SUM(cs.cs_ext_sales_price) AS metric_value,
    CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'high_volume' ELSE 'low_volume' END AS volume_category,
    (SELECT AVG(cs2.cs_list_price)
       FROM catalog_sales cs2
       WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk) AS avg_list_price
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_fy_week_seq = 10
    AND cp.cp_department = 'Home'
  GROUP BY w.w_warehouse_name, w.w_warehouse_sk
),
inventory_agg AS (
  SELECT
    w.w_warehouse_name AS warehouse_name,
    'inventory' AS metric_type,
    SUM(i.inv_quantity_on_hand) AS metric_value,
    CASE WHEN SUM(i.inv_quantity_on_hand) > 500 THEN 'high_stock' ELSE 'low_stock' END AS volume_category,
    NULL AS avg_list_price
  FROM inventory i
  JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
  JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_fy_week_seq = 10
  GROUP BY w.w_warehouse_name, w.w_warehouse_sk
)
SELECT
  combined.warehouse_name,
  combined.metric_type,
  combined.metric_value,
  combined.volume_category,
  combined.avg_list_price
FROM (
  SELECT warehouse_name, metric_type, metric_value, volume_category, avg_list_price
  FROM sales_agg
  UNION
  SELECT warehouse_name, metric_type, metric_value, volume_category, avg_list_price
  FROM inventory_agg
) AS combined
ORDER BY combined.metric_type, combined.warehouse_name
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
