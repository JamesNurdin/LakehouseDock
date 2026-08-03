SELECT
    wr.wr_order_number,
    wr.wr_return_amt,
    ws.ws_net_paid_inc_ship,
    ws.ws_ext_ship_cost
FROM tpcds.web_returns AS wr
JOIN tpcds.web_sales AS ws
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_item_sk = ws.ws_item_sk
WHERE wr.wr_web_page_sk = 2809
  AND ws.ws_ext_ship_cost > 1000
ORDER BY wr.wr_order_number
LIMIT 100
