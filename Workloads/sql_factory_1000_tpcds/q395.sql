SELECT ws.ws_item_sk,
       SUM(ws.ws_net_profit) AS total_sales_profit,
       COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
       SUM(ws.ws_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_after_returns,
       NTILE(4) OVER (ORDER BY SUM(ws.ws_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) DESC) AS profit_quartile,
       MAX(ws.ws_sold_date_sk) AS last_sale_date
FROM web_sales ws
LEFT JOIN catalog_returns cr
  ON ws.ws_order_number = cr.cr_order_number AND ws.ws_item_sk = cr.cr_item_sk
WHERE ws.ws_sold_date_sk BETWEEN 19990101 AND 19991231
  AND ws.ws_ship_mode_sk IS NOT NULL
GROUP BY ws.ws_item_sk
HAVING COALESCE(SUM(cr.cr_net_loss),0) < 5000
ORDER BY net_profit_after_returns ASC
