WITH customer_profit AS (
   SELECT
       cc.cc_division,
       cc.cc_division_name,
       cust.c_customer_sk,
       cust.c_customer_id,
       cust.c_first_name,
       cust.c_last_name,
       SUM(cs.cs_net_profit) AS customer_profit,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
       SUM(cs.cs_ext_sales_price) AS total_sales
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
   GROUP BY cc.cc_division, cc.cc_division_name, cust.c_customer_sk, cust.c_customer_id, cust.c_first_name, cust.c_last_name
),
customer_fav_ship AS (
   SELECT
       cs.cs_bill_customer_sk,
       sm.sm_ship_mode_id,
       COUNT(*) AS mode_cnt,
       ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY COUNT(*) DESC) AS rn
   FROM catalog_sales cs
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   GROUP BY cs.cs_bill_customer_sk, sm.sm_ship_mode_id
)
SELECT
   cp.cc_division_name,
   cp.c_customer_id,
   cp.c_first_name,
   cp.c_last_name,
   cp.customer_profit,
   cp.order_cnt,
   cp.total_sales,
   CASE
      WHEN cp.customer_profit >= 50000 THEN 'Platinum'
      WHEN cp.customer_profit >= 20000 THEN 'Gold'
      WHEN cp.customer_profit >= 5000 THEN 'Silver'
      ELSE 'Bronze'
   END AS profit_tier,
   DENSE_RANK() OVER (PARTITION BY cp.cc_division ORDER BY cp.customer_profit DESC) AS division_customer_rank,
   fav.sm_ship_mode_id AS favorite_ship_mode
FROM customer_profit cp
LEFT JOIN (
   SELECT cs_bill_customer_sk, sm_ship_mode_id
   FROM customer_fav_ship
   WHERE rn = 1
) fav ON cp.c_customer_sk = fav.cs_bill_customer_sk
ORDER BY cp.cc_division_name, division_customer_rank
LIMIT 20
