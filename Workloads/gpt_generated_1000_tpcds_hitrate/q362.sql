WITH sales_agg AS (
   SELECT
      d_sold.d_year AS sold_year,
      d_sold.d_month_seq AS sold_month_seq,
      i.i_category,
      c.c_customer_id,
      sm.sm_carrier,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      CASE WHEN ws.ws_ext_discount_amt > 100 THEN 'HighDiscount' ELSE 'LowDiscount' END AS discount_level
   FROM web_sales ws
   JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
   JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
   WHERE d_sold.d_year = 2001
     AND i.i_category_id IN (2, 4, 7)
     AND sm.sm_code = 'AIR'
),
grouped_agg AS (
   SELECT
      sold_year,
      sold_month_seq,
      i_category,
      discount_level,
      SUM(ws_ext_sales_price) AS total_sales,
      AVG(ws_net_profit) AS avg_profit,
      COUNT(DISTINCT c_customer_id) AS unique_customers
   FROM sales_agg
   GROUP BY CUBE (sold_year, sold_month_seq, i_category, discount_level)
   HAVING SUM(ws_ext_sales_price) > 10000
)
SELECT
   sold_year,
   sold_month_seq,
   i_category,
   discount_level,
   total_sales,
   avg_profit,
   unique_customers,
   RANK() OVER (PARTITION BY sold_year ORDER BY total_sales DESC) AS sales_rank
FROM grouped_agg
ORDER BY total_sales DESC
LIMIT 100
