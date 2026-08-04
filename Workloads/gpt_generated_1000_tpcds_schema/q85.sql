SELECT ws.ws_web_page_sk,
       COUNT(DISTINCT ws.ws_order_number) AS orders_returned,
       SUM(wr.wr_net_loss) AS total_net_loss,
       AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax
FROM tpcds.web_sales ws
JOIN tpcds.web_returns wr
  ON ws.ws_item_sk = wr.wr_item_sk
  AND ws.ws_order_number = wr.wr_order_number
WHERE ws.ws_ext_discount_amt > 2000
  AND wr.wr_return_amt_inc_tax > 500
GROUP BY ws.ws_web_page_sk
ORDER BY total_net_loss DESC
LIMIT 10
