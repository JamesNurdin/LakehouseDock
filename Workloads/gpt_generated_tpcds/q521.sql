SELECT
    wp.wp_type,
    date_dim.d_year,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_count
FROM web_sales ws
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim
  ON ws.ws_sold_date_sk = date_dim.d_date_sk
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND date_dim.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
GROUP BY wp.wp_type, date_dim.d_year
ORDER BY total_profit DESC
