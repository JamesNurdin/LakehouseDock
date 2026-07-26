WITH returns_agg AS (
  SELECT cr_item_sk AS item_sk,
         SUM(cr_net_loss) AS total_catalog_net_loss,
         SUM(cr_return_quantity) AS total_catalog_return_qty
  FROM catalog_returns
  GROUP BY cr_item_sk
), ranked_sales AS (
  SELECT
    i.i_brand AS brand,
    i.i_color AS color,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    AVG(ws.ws_net_profit) OVER (PARTITION BY i.i_brand ORDER BY ws.ws_sold_date_sk ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS moving_avg_30d_profit,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_sign,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand, ws.ws_sold_date_sk ORDER BY ws.ws_net_profit DESC) AS rn,
    SUM(ws.ws_net_profit) OVER (PARTITION BY i.i_brand) AS total_brand_profit,
    COALESCE(ra.total_catalog_net_loss, 0) AS total_catalog_net_loss,
    CASE WHEN COALESCE(ra.total_catalog_net_loss, 0) > 0 THEN 'Has Loss' ELSE 'No Loss' END AS catalog_loss_flag
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN returns_agg ra ON i.i_item_sk = ra.item_sk
)
SELECT
  brand,
  color,
  ws_sold_date_sk,
  ws_quantity,
  ws_net_profit,
  moving_avg_30d_profit,
  profit_sign,
  total_catalog_net_loss,
  catalog_loss_flag,
  DENSE_RANK() OVER (ORDER BY total_brand_profit DESC) AS brand_profit_rank
FROM ranked_sales
WHERE rn = 1
ORDER BY brand_profit_rank, ws_sold_date_sk
LIMIT 15
