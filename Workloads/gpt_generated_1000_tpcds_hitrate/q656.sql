WITH
catalog_customers AS (
   SELECT DISTINCT cs.cs_bill_customer_sk AS cust_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
store_return_customers AS (
   SELECT DISTINCT sr.sr_customer_sk AS cust_sk
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
web_customers AS (
   SELECT DISTINCT ws.ws_bill_customer_sk AS cust_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
web_return_customers AS (
   SELECT DISTINCT wr.wr_refunded_customer_sk AS cust_sk
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
/*** set operations ***/
diff_customers AS (
   SELECT cust_sk FROM catalog_customers
   EXCEPT
   SELECT cust_sk FROM store_return_customers
),
intersect_customers AS (
   SELECT cust_sk FROM web_customers
   INTERSECT
   SELECT cust_sk FROM web_return_customers
),
/*** main aggregation ***/
aggregated AS (
   SELECT
       c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       d1.d_year,
       SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
       SUM(ws.ws_ext_sales_price) AS total_web_sales,
       COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
       COUNT(DISTINCT ws.ws_order_number) AS web_orders
   FROM customer c
   JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
   JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
   JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
   JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk AND ws.ws_item_sk = i.i_item_sk
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
   JOIN time_dim t2 ON sr.sr_return_time_sk = t2.t_time_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
   JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   WHERE d1.d_year = 2001
     AND i.i_brand = 'Brand#12'
     AND ca.ca_state = 'CA'
     AND ib.ib_lower_bound >= 50000
     AND sr.sr_fee > 30
     AND c.c_customer_sk IN (SELECT cust_sk FROM diff_customers)
     AND c.c_customer_sk IN (SELECT cust_sk FROM intersect_customers)
   GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d1.d_year
),
ranked AS (
   SELECT
       *,
       ROW_NUMBER() OVER (ORDER BY (total_catalog_sales + total_web_sales) DESC) AS global_rn,
       RANK() OVER (PARTITION BY d_year ORDER BY (total_catalog_sales + total_web_sales) DESC) AS yearly_rank
   FROM aggregated
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    d_year,
    total_catalog_sales,
    total_web_sales,
    catalog_orders,
    web_orders,
    global_rn,
    yearly_rank
FROM ranked
WHERE yearly_rank <= 5
ORDER BY d_year, yearly_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
