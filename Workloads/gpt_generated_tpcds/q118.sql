SELECT
  t_sales.t_hour AS sale_hour,
  COUNT(DISTINCT ws.ws_order_number) AS num_sales_orders,
  SUM(ws.ws_net_profit) AS total_sales_profit,
  COUNT(DISTINCT wr.wr_order_number) AS num_return_orders,
  SUM(wr.wr_net_loss) AS total_return_loss,
  (SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS net_profit_after_returns,
  AVG(ws.ws_ext_discount_amt) AS avg_sales_discount,
  AVG(wr.wr_return_amt_inc_tax) AS avg_return_amount_inc_tax
FROM web_sales ws
JOIN time_dim t_sales
  ON ws.ws_sold_time_sk = t_sales.t_time_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = ws.ws_item_sk
  AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN time_dim t_returns
  ON wr.wr_returned_time_sk = t_returns.t_time_sk
WHERE t_sales.t_hour BETWEEN 8 AND 20
GROUP BY t_sales.t_hour
ORDER BY t_sales.t_hour
