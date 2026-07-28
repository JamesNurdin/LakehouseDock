SELECT DISTINCT
    ws_order_number,
    ws_sold_date_sk,
    ws_net_paid,
    ws_net_profit
FROM tpcds.web_sales
WHERE ws_ship_hdemo_sk = 39
  AND ws_coupon_amt > 1000
ORDER BY ws_net_profit DESC
LIMIT 100
