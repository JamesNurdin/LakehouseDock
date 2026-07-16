WITH agg AS (
  SELECT
    ws.ws_web_site_sk AS web_site_id,
    ws.ws_sold_date_sk AS sold_date_sk,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss
  FROM web_sales ws
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk
  HAVING SUM(ws.ws_ext_sales_price) > 10000
)
SELECT
  web_site_id,
  sold_date_sk,
  total_sales,
  total_return_amount,
  total_net_profit,
  total_return_loss,
  (total_net_profit - total_return_loss) AS net_profit_after_returns,
  RANK() OVER (PARTITION BY sold_date_sk ORDER BY (total_net_profit - total_return_loss) DESC) AS profit_rank
FROM agg
ORDER BY sold_date_sk, net_profit_after_returns DESC
LIMIT 200
