WITH sales_y AS (
  SELECT
    c.c_customer_id,
    wp.wp_web_page_id,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE wp.wp_autogen_flag = 'Y'
    AND d.d_year = 2002
  GROUP BY c.c_customer_id, wp.wp_web_page_id
),
sales_n AS (
  SELECT
    c.c_customer_id,
    wp.wp_web_page_id,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE wp.wp_autogen_flag = 'N'
    AND d.d_year = 2002
  GROUP BY c.c_customer_id, wp.wp_web_page_id
)
SELECT
  c_customer_id,
  wp_web_page_id,
  total_sales,
  total_profit,
  profit_category
FROM (
  SELECT c_customer_id, wp_web_page_id, total_sales, total_profit, profit_category FROM sales_y
  UNION
  SELECT c_customer_id, wp_web_page_id, total_sales, total_profit, profit_category FROM sales_n
) AS combined
ORDER BY total_sales DESC
LIMIT 100
