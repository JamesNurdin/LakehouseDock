SELECT
  ws.ws_order_number,
  ws.ws_item_sk,
  ws.ws_quantity,
  ws.ws_net_profit,
  wr.wr_return_quantity,
  wr.wr_return_amt,
  wr.wr_return_tax,
  wr.wr_fee,
  wr.wr_return_ship_cost,
  (ws.ws_net_profit - (wr.wr_return_amt + wr.wr_return_tax + wr.wr_fee + wr.wr_return_ship_cost)) AS adjusted_profit,
  r.r_reason_desc,
  RANK() OVER (ORDER BY (ws.ws_net_profit - (wr.wr_return_amt + wr.wr_return_tax + wr.wr_fee + wr.wr_return_ship_cost)) ASC) AS profit_rank_asc
FROM web_sales ws
JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
 AND ws.ws_item_sk = wr.wr_item_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE ws.ws_net_profit > 0
  AND wr.wr_return_quantity > 1
ORDER BY ws.ws_order_number, adjusted_profit DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY
