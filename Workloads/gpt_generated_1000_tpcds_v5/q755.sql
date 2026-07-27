WITH raw_sales AS (
   SELECT
       c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       hd.hd_vehicle_count,
       cp.cp_catalog_number,
       cs.cs_sold_date_sk,
       cs.cs_order_number,
       cs.cs_net_paid,
       cs.cs_ext_discount_amt,
       ss.ss_sales_price,
       ss.ss_ext_tax,
       wp.wp_type
   FROM catalog_sales cs
   JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c
       ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd
       ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN store_sales ss
       ON ss.ss_customer_sk = c.c_customer_sk
          AND ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN web_page wp
       ON wp.wp_customer_sk = c.c_customer_sk
   WHERE cp.cp_catalog_number IN (12, 18)
     AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
     AND ss.ss_sales_price > 20.00
     AND wp.wp_type = 'Content'
),
agg_sales AS (
   SELECT
       c_customer_sk,
       c_first_name,
       c_last_name,
       hd_vehicle_count,
       CASE WHEN hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category,
       COUNT(DISTINCT cs_order_number) AS distinct_orders,
       SUM(cs_net_paid) AS total_net_paid,
       AVG(ss_sales_price) AS avg_sales_price,
       MIN(cs_ext_discount_amt) AS min_discount,
       MAX(cs_ext_discount_amt) AS max_discount
   FROM raw_sales
   GROUP BY
       c_customer_sk,
       c_first_name,
       c_last_name,
       hd_vehicle_count,
       CASE WHEN hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END
   HAVING SUM(cs_net_paid) > 1000
)
SELECT
   a.c_customer_sk,
   a.c_first_name,
   a.c_last_name,
   a.vehicle_category,
   a.distinct_orders,
   a.total_net_paid,
   a.avg_sales_price,
   a.min_discount,
   a.max_discount,
   (SELECT AVG(cs_ext_discount_amt) FROM raw_sales) AS overall_avg_discount,
   RANK() OVER (PARTITION BY a.vehicle_category ORDER BY a.total_net_paid DESC) AS revenue_rank,
   SUM(a.total_net_paid) OVER (PARTITION BY a.vehicle_category) AS vehicle_category_total_net
FROM agg_sales a
ORDER BY a.total_net_paid DESC
LIMIT 100
