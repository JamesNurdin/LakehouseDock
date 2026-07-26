WITH combined_returns AS (
  SELECT cr_item_sk AS item_sk,
         cr_returned_date_sk AS date_sk,
         cr_return_quantity AS quantity,
         cr_net_loss AS net_loss,
         'catalog' AS source
  FROM catalog_returns
  UNION ALL
  SELECT sr_item_sk AS item_sk,
         sr_returned_date_sk AS date_sk,
         sr_return_quantity AS quantity,
         sr_net_loss AS net_loss,
         'store' AS source
  FROM store_returns
),
sales_agg AS (
  SELECT ws_item_sk AS item_sk,
         SUM(ws_net_profit) AS total_net_profit,
         SUM(ws_quantity) AS total_sales_quantity
  FROM web_sales
  GROUP BY ws_item_sk
)
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_brand,
  i.i_category,
  SUM(cr.quantity) AS total_return_quantity,
  SUM(cr.net_loss) AS total_return_net_loss,
  COALESCE(ws.total_net_profit, 0) AS total_sales_net_profit,
  CASE WHEN COALESCE(ws.total_net_profit, 0) = 0 THEN NULL
       ELSE SUM(cr.net_loss) / ws.total_net_profit END AS loss_to_profit_ratio,
  CASE
    WHEN SUM(cr.net_loss) > 5000 THEN 'High Loss'
    WHEN SUM(cr.net_loss) > 1000 THEN 'Medium Loss'
    ELSE 'Low Loss'
  END AS loss_category,
  RANK() OVER (ORDER BY SUM(cr.net_loss) DESC) AS loss_rank
FROM combined_returns cr
JOIN item i ON cr.item_sk = i.i_item_sk
LEFT JOIN sales_agg ws ON i.i_item_sk = ws.item_sk
GROUP BY i.i_item_id, i.i_product_name, i.i_brand, i.i_category, ws.total_net_profit
HAVING SUM(cr.net_loss) > 0
ORDER BY loss_rank
LIMIT 10
