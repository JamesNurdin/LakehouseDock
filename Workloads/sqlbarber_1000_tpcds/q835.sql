SELECT
  c.c_customer_id,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  COUNT(*) AS sales_count
FROM
  web_sales ws
JOIN
  customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN
  web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN
  (
    SELECT DISTINCT wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk = 2451665
  ) r
    ON ws.ws_order_number = r.wr_order_number
WHERE
  ws.ws_sold_date_sk = 2452401
GROUP BY
  c.c_customer_id
HAVING
  SUM(ws.ws_ext_sales_price) > 1623.09
