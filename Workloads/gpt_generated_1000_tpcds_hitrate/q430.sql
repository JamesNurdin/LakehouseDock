WITH sales_agg AS (
  SELECT
    d.d_year,
    c.c_customer_id,
    cd.cd_gender,
    ws.ws_net_profit AS web_net_profit,
    ss.ss_net_profit AS store_net_profit,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN web_page wp TABLESAMPLE BERNOULLI (10) ON ws.ws_web_page_sk = wp.wp_web_page_sk
  RIGHT OUTER JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    AND ss.ss_customer_sk = c.c_customer_sk
  WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    AND c.c_birth_year BETWEEN 1950 AND 1960
    AND cd.cd_education_status = 'College'
    AND ws.ws_quantity > 1
    AND ss.ss_quantity > 0
    AND wp.wp_image_count > 2
  GROUP BY d.d_year, c.c_customer_id, cd.cd_gender, ws.ws_net_profit, ss.ss_net_profit
)
SELECT
  year,
  customer_id,
  gender,
  SUM(web_sales) AS total_web_sales,
  SUM(store_sales) AS total_store_sales,
  AVG(web_net_profit) AS avg_web_profit,
  AVG(store_net_profit) AS avg_store_profit,
  SUM(web_orders) AS total_web_orders,
  SUM(store_tickets) AS total_store_tickets
FROM (
  SELECT
    d_year AS year,
    c_customer_id AS customer_id,
    cd_gender AS gender,
    web_sales,
    store_sales,
    web_net_profit,
    store_net_profit,
    web_orders,
    store_tickets
  FROM sales_agg
) agg
GROUP BY year, customer_id, gender
HAVING SUM(web_sales) > 1000
ORDER BY total_web_sales DESC, year
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
