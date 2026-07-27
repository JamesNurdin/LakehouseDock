WITH sales_data AS (
  SELECT
    ws.ws_warehouse_sk,
    ws.ws_sold_time_sk,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ws.ws_quantity
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE
    td.t_hour BETWEEN 12 AND 14
    AND w.w_state = 'CA'
    AND c.c_birth_year = 1975
    AND wp.wp_type = 'product'
    AND ws.ws_sales_price > 30
    AND ws.ws_coupon_amt < 500
),
returns_data AS (
  SELECT
    ws.ws_warehouse_sk,
    wr.wr_returned_time_sk,
    wr.wr_return_amt,
    wr.wr_net_loss,
    wr.wr_return_quantity
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
  JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE
    td.t_hour BETWEEN 12 AND 14
    AND w.w_state = 'CA'
    AND wr.wr_account_credit > 100
    AND wr.wr_return_quantity > 0
),
combined AS (
  SELECT
    sd.ws_warehouse_sk AS warehouse_sk,
    td.t_hour,
    sd.ws_ext_sales_price AS amount,
    sd.ws_net_profit AS profit,
    sd.ws_quantity AS qty,
    'sale' AS record_type
  FROM sales_data sd
  JOIN time_dim td ON sd.ws_sold_time_sk = td.t_time_sk
  UNION ALL
  SELECT
    rd.ws_warehouse_sk,
    td.t_hour,
    -rd.wr_return_amt AS amount,
    -rd.wr_net_loss AS profit,
    rd.wr_return_quantity AS qty,
    'return' AS record_type
  FROM returns_data rd
  JOIN time_dim td ON rd.wr_returned_time_sk = td.t_time_sk
)
SELECT
  w.w_warehouse_name,
  c.t_hour,
  SUM(CASE WHEN c.record_type = 'sale' THEN c.amount ELSE 0 END) AS total_sales_amount,
  SUM(CASE WHEN c.record_type = 'return' THEN -c.amount ELSE 0 END) AS total_return_amount,
  SUM(CASE WHEN c.record_type = 'sale' THEN c.profit ELSE 0 END) AS total_sales_profit,
  SUM(CASE WHEN c.record_type = 'return' THEN -c.profit ELSE 0 END) AS total_return_loss,
  COUNT(*) FILTER (WHERE c.record_type = 'sale') AS sales_transactions,
  COUNT(*) FILTER (WHERE c.record_type = 'return') AS return_transactions,
  MIN(c.amount) AS min_amount,
  MAX(c.amount) AS max_amount,
  (SELECT COUNT(*) FROM web_page wp2 WHERE wp2.wp_type = 'product') AS total_product_pages
FROM combined c
JOIN warehouse w ON c.warehouse_sk = w.w_warehouse_sk
GROUP BY w.w_warehouse_name, c.t_hour
ORDER BY w.w_warehouse_name, c.t_hour
LIMIT 100
