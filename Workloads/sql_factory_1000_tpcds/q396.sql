SELECT ws.ws_item_sk,
       AVG(ws.ws_net_profit) AS avg_profit,
       SUM(cr.cr_net_loss) AS total_return_loss,
       AVG(ws.ws_net_profit) - COALESCE(SUM(cr.cr_net_loss),0) AS adjusted_avg_profit,
       ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk) AS sale_seq,
       CASE WHEN AVG(ws.ws_net_profit) > 2000 THEN 'Premium' ELSE 'Standard' END AS profit_tier
FROM web_sales ws
LEFT JOIN catalog_returns cr
  ON ws.ws_order_number = cr.cr_order_number AND ws.ws_item_sk = cr.cr_item_sk
WHERE ws.ws_sold_date_sk BETWEEN 19990101 AND 19991231
  AND ws.ws_net_paid_inc_tax > 0
GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
ORDER BY adjusted_avg_profit DESC
LIMIT 100
