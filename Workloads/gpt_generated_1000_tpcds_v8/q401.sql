SELECT
  ws_item_sk,
  ws_quantity,
  ws_net_paid,
  ws_net_profit
FROM tpcds.web_sales
WHERE ws_wholesale_cost > 50.00
  AND ws_net_paid < 2000.00
ORDER BY ws_net_paid DESC
