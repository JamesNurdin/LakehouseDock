SELECT DISTINCT
  ws_ship_hdemo_sk,
  ws_coupon_amt,
  ws_list_price,
  ws_net_profit
FROM tpcds.web_sales
WHERE ws_ship_hdemo_sk IN (1587, 6132)
  AND ws_coupon_amt > 500.00
ORDER BY ws_net_profit DESC
LIMIT 100
