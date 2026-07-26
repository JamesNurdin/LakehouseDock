WITH catalog_agg AS (
  SELECT cr_item_sk AS item_sk,
         AVG(cr_return_quantity) AS avg_cr_qty,
         SUM(cr_net_loss) AS total_cr_loss
  FROM catalog_returns
  GROUP BY cr_item_sk
),
store_agg AS (
  SELECT sr_item_sk AS item_sk,
         AVG(sr_return_quantity) AS avg_sr_qty,
         SUM(sr_net_loss) AS total_sr_loss
  FROM store_returns
  GROUP BY sr_item_sk
),
sales_agg AS (
  SELECT ws_item_sk AS item_sk,
         AVG(ws_quantity) AS avg_ws_qty,
         SUM(ws_net_profit) AS total_ws_profit
  FROM web_sales
  GROUP BY ws_item_sk
)
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_brand,
  i.i_category,
  COALESCE(ca.avg_cr_qty, 0) AS avg_catalog_return_qty,
  COALESCE(sa.avg_sr_qty, 0) AS avg_store_return_qty,
  COALESCE(wa.avg_ws_qty, 0) AS avg_sales_qty,
  (COALESCE(wa.avg_ws_qty, 0) - (COALESCE(ca.avg_cr_qty, 0) + COALESCE(sa.avg_sr_qty, 0)) / 2) AS qty_diff,
  CASE WHEN (COALESCE(wa.avg_ws_qty, 0) - (COALESCE(ca.avg_cr_qty, 0) + COALESCE(sa.avg_sr_qty, 0)) / 2) > 0 THEN 'Higher Sales' ELSE 'Higher Returns' END AS sales_vs_returns,
  RANK() OVER (ORDER BY (COALESCE(wa.avg_ws_qty, 0) - (COALESCE(ca.avg_cr_qty, 0) + COALESCE(sa.avg_sr_qty, 0)) / 2) DESC) AS qty_diff_rank
FROM item i
LEFT JOIN catalog_agg ca ON i.i_item_sk = ca.item_sk
LEFT JOIN store_agg sa ON i.i_item_sk = sa.item_sk
LEFT JOIN sales_agg wa ON i.i_item_sk = wa.item_sk
WHERE i.i_brand IS NOT NULL
ORDER BY qty_diff_rank
LIMIT 20
