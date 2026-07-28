WITH sales_agg AS (
   SELECT
       d_sold.d_year,
       ca.ca_state,
       sm.sm_carrier,
       wp.wp_type,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(DISTINCT ws.ws_order_number) AS order_count,
       COUNT(DISTINCT wp.wp_url) AS distinct_pages,
       CASE
           WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) > 0.2 THEN 'High'
           WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) > 0.1 THEN 'Medium'
           ELSE 'Low'
       END AS profit_category
   FROM tpcds.web_sales ws
   JOIN tpcds.date_dim d_sold
     ON ws.ws_sold_date_sk = d_sold.d_date_sk
   JOIN tpcds.date_dim d_ship
     ON ws.ws_ship_date_sk = d_ship.d_date_sk
   JOIN tpcds.customer_address ca
     ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN tpcds.ship_mode sm
     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE d_sold.d_year BETWEEN 2001 AND 2003
     AND d_ship.d_month_seq BETWEEN 1200 AND 1300
     AND ca.ca_state = 'CA'
     AND sm.sm_carrier IN ('ALLIANCE', 'GREAT EASTERN')
     AND wp.wp_type = 'home'
     AND ws.ws_quantity >= 5
     AND ws.ws_net_paid >= 100
   GROUP BY d_sold.d_year, ca.ca_state, sm.sm_carrier, wp.wp_type
   HAVING SUM(ws.ws_ext_sales_price) > 1000
)
SELECT
   COALESCE(d_year, -1) AS year,
   ca_state,
   sm_carrier,
   profit_category,
   SUM(total_sales) AS sales,
   SUM(total_profit) AS profit,
   SUM(order_count) AS orders,
   SUM(distinct_pages) AS distinct_pages
FROM sales_agg
GROUP BY ROLLUP (d_year, ca_state, sm_carrier, profit_category)
ORDER BY year, ca_state, sm_carrier, profit_category
LIMIT 100
