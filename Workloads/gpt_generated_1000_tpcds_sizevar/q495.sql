WITH date_1908 AS (
   SELECT *
   FROM date_dim
   WHERE d_year = 1908
),
date_1907 AS (
   SELECT *
   FROM date_dim
   WHERE d_year = 1907
),
store_emp_filter AS (
   SELECT s_store_sk
   FROM store
   WHERE s_number_employees > 200
   INTERSECT
   SELECT s_store_sk
   FROM store
   WHERE s_number_employees < 300
)
SELECT
   s.s_store_sk,
   s.s_store_name,
   d.d_year,
   cc.cc_name,
   sm.sm_type,
   w.w_warehouse_name,
   SUM(cs.cs_net_paid) AS total_net_paid,
   COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
   CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
   RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS sales_rank,
   (SELECT AVG(cs2.cs_net_paid)
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = s.s_store_sk
      AND cs2.cs_sold_date_sk = d.d_date_sk) AS avg_net_paid_same_store_day
FROM catalog_sales cs
JOIN date_1908 d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE cs.cs_quantity > 5
  AND sr.sr_return_quantity > 0
  AND s.s_state = 'CA'
  AND w.w_state = 'CA'
  AND s.s_store_sk IN (SELECT s_store_sk FROM store_emp_filter)
GROUP BY s.s_store_sk, s.s_store_name, d.d_year, cc.cc_name, sm.sm_type, w.w_warehouse_name, d.d_date_sk

UNION DISTINCT

SELECT
   s.s_store_sk,
   s.s_store_name,
   d.d_year,
   cc.cc_name,
   sm.sm_type,
   w.w_warehouse_name,
   SUM(cs.cs_net_paid) * 0.9 AS total_net_paid,
   COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
   CASE WHEN SUM(cs.cs_net_profit) < 0 THEN 'LOSS' ELSE 'PROFIT' END AS profit_flag,
   RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS sales_rank,
   (SELECT AVG(cs2.cs_net_paid)
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = s.s_store_sk
      AND cs2.cs_sold_date_sk = d.d_date_sk) AS avg_net_paid_same_store_day
FROM catalog_sales cs
JOIN date_1907 d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE cs.cs_quantity > 10
  AND sr.sr_return_quantity > 0
  AND s.s_state = 'CA'
  AND w.w_state = 'CA'
  AND s.s_store_sk IN (SELECT s_store_sk FROM store_emp_filter)
GROUP BY s.s_store_sk, s.s_store_name, d.d_year, cc.cc_name, sm.sm_type, w.w_warehouse_name, d.d_date_sk
LIMIT 100
