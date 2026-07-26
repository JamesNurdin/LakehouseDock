SELECT
  i.i_category,
  COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
  COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
  COUNT(DISTINCT ws.ws_order_number) AS web_orders,
  SUM(ws.ws_net_profit) FILTER (WHERE ws.ws_net_profit > 0) AS positive_web_profit,
  ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_row_num
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_return_amount > 0
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_return_amt > 0
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
GROUP BY i.i_category
HAVING COUNT(DISTINCT ws.ws_order_number) >= 10
ORDER BY positive_web_profit DESC
LIMIT 10
