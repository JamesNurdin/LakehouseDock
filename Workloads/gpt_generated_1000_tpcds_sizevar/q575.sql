WITH base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_ext_sales_price,
       cs.cs_quantity,
       cs.cs_ext_discount_amt,
       d1.d_year,
       sm.sm_code,
       w.w_warehouse_name,
       hd.hd_buy_potential,
       r.r_reason_desc,
       wp.wp_url,
       ws.web_name,
       c.c_customer_id,
       s.s_store_id
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   FULL OUTER JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk AND i.inv_date_sk = d1.d_date_sk
   JOIN web_returns wr ON wr.wr_returned_date_sk = d1.d_date_sk AND wr.wr_refunded_customer_sk = c.c_customer_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN web_site ws ON ws.web_open_date_sk = d1.d_date_sk
   JOIN store s ON s.s_closed_date_sk = d1.d_date_sk
   WHERE d1.d_year = 2001
     AND cs.cs_quantity > 1
     AND cs.cs_ext_discount_amt < 500
     AND sm.sm_code = 'AIR'
     AND w.w_warehouse_name LIKE '%East%'
     AND hd.hd_buy_potential = 'HIGH'
     AND EXISTS (SELECT 1 FROM web_returns wr2 WHERE wr2.wr_order_number = cs.cs_order_number AND wr2.wr_return_amt > 0)
),
agg AS (
   SELECT
       cs_order_number,
       d_year,
       SUM(cs_ext_sales_price) AS total_sales,
       AVG(cs_quantity) AS avg_qty,
       COUNT(*) AS cnt,
       ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cs_ext_sales_price) DESC) AS rn
   FROM base
   GROUP BY cs_order_number, d_year
),
top5 AS (
   SELECT cs_order_number, total_sales FROM agg WHERE rn <= 5
),
high_sales AS (
   SELECT cs_order_number, total_sales FROM agg WHERE total_sales > 10000
),
low_sales AS (
   SELECT cs_order_number, total_sales FROM agg WHERE total_sales < 5000
)
SELECT *
FROM (
   SELECT cs_order_number, total_sales FROM top5
   UNION
   SELECT cs_order_number, total_sales FROM high_sales
) u
EXCEPT
SELECT cs_order_number, total_sales FROM low_sales
ORDER BY total_sales DESC
LIMIT 100
