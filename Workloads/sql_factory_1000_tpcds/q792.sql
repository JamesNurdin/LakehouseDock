WITH combined_sales AS (
  SELECT cs_item_sk AS item_sk,
         cs_net_profit AS net_profit,
         cs_sold_date_sk AS date_sk,
         'catalog' AS channel
  FROM catalog_sales
  UNION ALL
  SELECT ws_item_sk AS item_sk,
         ws_net_profit AS net_profit,
         ws_sold_date_sk AS date_sk,
         'web' AS channel
  FROM web_sales
),
aggregated AS (
  SELECT i.i_item_id AS item_id,
         i.i_product_name AS product_name,
         SUM(cs_ws.net_profit) AS total_net_profit,
         COUNT(*) AS total_transactions,
         SUM(CASE WHEN cs_ws.channel = 'catalog' THEN 1 ELSE 0 END) AS catalog_transactions,
         SUM(CASE WHEN cs_ws.channel = 'web' THEN 1 ELSE 0 END) AS web_transactions
  FROM combined_sales cs_ws
  JOIN item i ON i.i_item_sk = cs_ws.item_sk
  JOIN date_dim d ON d.d_date_sk = cs_ws.date_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_id, i.i_product_name
)
SELECT
  item_id,
  product_name,
  total_net_profit,
  total_transactions,
  catalog_transactions,
  web_transactions,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
WHERE total_net_profit > 0
ORDER BY total_net_profit DESC
LIMIT 10
