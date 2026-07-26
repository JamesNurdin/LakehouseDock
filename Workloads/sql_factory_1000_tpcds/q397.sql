SELECT ws.ws_item_sk,
       SUM(ws.ws_net_profit) AS total_sales_profit,
       COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
       SUM(ws.ws_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_after_returns,
       CASE WHEN ws.ws_ship_mode_sk = 1 THEN 'Air'
            WHEN ws.ws_ship_mode_sk = 2 THEN 'Ground'
            ELSE 'Other' END AS ship_mode_category,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
       RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
FROM web_sales ws
LEFT JOIN catalog_returns cr
  ON ws.ws_order_number = cr.cr_order_number AND ws.ws_item_sk = cr.cr_item_sk
WHERE ws.ws_sold_date_sk BETWEEN 19990101 AND 19991231
  AND ws.ws_net_profit <> 0
GROUP BY ws.ws_item_sk, ws.ws_ship_mode_sk
ORDER BY sales_rank
LIMIT 50
