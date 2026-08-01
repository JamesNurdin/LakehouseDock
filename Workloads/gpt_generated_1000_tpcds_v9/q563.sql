WITH returns AS (
  SELECT
    i.i_category AS category,
    i.i_brand AS brand,
    'ReturnAmt' AS metric_type,
    SUM(wr.wr_return_amt_inc_tax) AS metric_value
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wr.wr_return_amt_inc_tax > 0
    AND EXISTS (
      SELECT 1 FROM inventory inv
      WHERE inv.inv_item_sk = i.i_item_sk
        AND inv.inv_quantity_on_hand > 100
    )
  GROUP BY i.i_category, i.i_brand
),
inventory_agg AS (
  SELECT
    i.i_category AS category,
    i.i_brand AS brand,
    'InventoryQty' AS metric_type,
    SUM(inv.inv_quantity_on_hand) AS metric_value
  FROM inventory inv
  JOIN item i ON inv.inv_item_sk = i.i_item_sk
  JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE inv.inv_quantity_on_hand > 0
    AND w.w_gmt_offset BETWEEN -5 AND 5
    AND inv.inv_item_sk IN (SELECT DISTINCT wr_item_sk FROM web_returns)
  GROUP BY i.i_category, i.i_brand
),
union_data AS (
  SELECT category, brand, metric_type, metric_value FROM returns
  UNION ALL
  SELECT category, brand, metric_type, metric_value FROM inventory_agg
)
SELECT
  category,
  brand,
  metric_type,
  SUM(metric_value) AS total_metric
FROM union_data
GROUP BY GROUPING SETS (
  (category, brand, metric_type),
  (category, metric_type),
  (brand, metric_type),
  (metric_type)
)
HAVING SUM(metric_value) > 1000
ORDER BY metric_type, category, brand, total_metric DESC
LIMIT 100
