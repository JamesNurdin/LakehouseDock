WITH sampled_sales AS (
   SELECT *
   FROM web_sales
   TABLESAMPLE BERNOULLI (10)
   WHERE ws_sold_date_sk BETWEEN 2450000 AND 2459999
),
high_value_customers AS (
   SELECT ws_bill_customer_sk
   FROM sampled_sales
   WHERE ws_ext_sales_price > 10000
   GROUP BY ws_bill_customer_sk
   HAVING COUNT(*) >= 2
),
agg AS (
   SELECT
      sm.sm_carrier AS carrier_or_warehouse,
      CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END AS carrier_type,
      SUM(s.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS order_cnt
   FROM sampled_sales s
   JOIN ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_site ws ON s.ws_web_site_sk = ws.web_site_sk
   WHERE sm.sm_carrier IN ('USPS', 'PRIVATECARRIER')
     AND ws.web_manager = 'John Thomas'
     AND s.ws_bill_customer_sk IN (SELECT ws_bill_customer_sk FROM high_value_customers)
     AND EXISTS (
         SELECT 1 FROM customer c
         WHERE c.c_customer_sk = s.ws_bill_customer_sk
           AND c.c_preferred_cust_flag = 'Y'
     )
   GROUP BY sm.sm_carrier,
            CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END
   UNION ALL
   SELECT
      w.w_warehouse_name AS carrier_or_warehouse,
      'Warehouse' AS carrier_type,
      SUM(s.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS order_cnt
   FROM sampled_sales s
   JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
   WHERE w.w_state = 'CA'
   GROUP BY w.w_warehouse_name
)
SELECT
   a.carrier_or_warehouse,
   a.carrier_type,
   a.total_sales,
   a.order_cnt,
   (SELECT AVG(ws_ext_discount_amt) FROM sampled_sales) AS avg_discount,
   d.run_date
FROM agg a
CROSS JOIN (SELECT CURRENT_DATE AS run_date) d
ORDER BY a.total_sales DESC
LIMIT 100
