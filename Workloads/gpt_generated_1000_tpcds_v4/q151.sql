SELECT
    ws.ws_order_number,
    ws.ws_bill_customer_sk,
    wr.wr_return_amt,
    ws.ws_net_profit,
    wr.wr_return_quantity
FROM tpcds.web_sales ws
JOIN tpcds.web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
WHERE wr.wr_return_ship_cost > 200.00
  AND ws.ws_bill_customer_sk = 3100363
ORDER BY ws.ws_order_number DESC
LIMIT 100
