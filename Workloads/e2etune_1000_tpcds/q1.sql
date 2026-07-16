SELECT
  wp.wp_type,
  ws.ws_sold_date_sk AS sold_date_key,
  COUNT(DISTINCT ws.ws_order_number) AS orders,
  SUM(ws.ws_quantity) AS total_quantity,
  SUM(ws.ws_net_paid) AS total_net_paid,
  SUM(ws.ws_net_profit) AS total_net_profit,
  AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
  SUM(ws.ws_ext_tax) AS total_tax
FROM web_sales ws
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ws.ws_sold_date_sk BETWEEN 20210101 AND 20210131
  AND ws.ws_quantity > 1
  AND wp.wp_type IN ('product', 'category')
GROUP BY wp.wp_type, ws.ws_sold_date_sk
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 10
