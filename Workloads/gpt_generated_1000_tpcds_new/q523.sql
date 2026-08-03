WITH base AS (
   SELECT
       sr.sr_ticket_number,
       d.d_year,
       t.t_hour,
       c.c_customer_id,
       hd.hd_income_band_sk,
       cs.cs_ext_sales_price,
       w.w_warehouse_name,
       ws.ws_net_paid_inc_ship,
       (
           SELECT SUM(sr3.sr_return_amt)
           FROM store_returns sr3
           WHERE sr3.sr_customer_sk = c.c_customer_sk
       ) AS cust_total_return_amt,
       CASE WHEN cs.cs_ext_sales_price > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category,
       split(c.c_customer_id, '-') AS cust_id_parts
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND t.t_shift = 'first'
     AND w.w_state = 'CA'
), exploded AS (
   SELECT
       b.*,
       id_part
   FROM base b
   CROSS JOIN UNNEST(b.cust_id_parts) AS t(id_part)
), unioned AS (
   SELECT DISTINCT
       sr_ticket_number,
       d_year,
       t_hour,
       c_customer_id,
       hd_income_band_sk,
       cs_ext_sales_price,
       w_warehouse_name,
       ws_net_paid_inc_ship,
       cust_total_return_amt,
       sales_category
   FROM exploded
   UNION
   SELECT DISTINCT
       sr_ticket_number,
       d_year,
       t_hour,
       c_customer_id,
       hd_income_band_sk,
       cs_ext_sales_price * 0.9 AS cs_ext_sales_price,
       w_warehouse_name,
       ws_net_paid_inc_ship,
       cust_total_return_amt,
       sales_category
   FROM exploded
   WHERE sales_category = 'HIGH'
)
SELECT
   sr_ticket_number,
   d_year,
   t_hour,
   c_customer_id,
   hd_income_band_sk,
   cs_ext_sales_price,
   w_warehouse_name,
   ws_net_paid_inc_ship,
   cust_total_return_amt,
   sales_category,
   ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY cs_ext_sales_price DESC) AS sales_rank,
   SUM(cs_ext_sales_price) OVER (PARTITION BY d_year ORDER BY cs_ext_sales_price ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales
FROM unioned
ORDER BY cs_ext_sales_price DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
