WITH call_center_sales AS (
   SELECT
       cc.cc_call_center_sk,
       cc.cc_name,
       cc.cc_division_name,
       sm.sm_ship_mode_id,
       SUM(cs.cs_net_profit) AS total_profit,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
       AVG(cs.cs_ext_discount_amt) AS avg_discount,
       COUNT(DISTINCT cust.c_customer_id) AS distinct_customers
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
   GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_division_name, sm.sm_ship_mode_id
),
most_popular_ship_mode AS (
   SELECT
       cc_call_center_sk,
       sm_ship_mode_id,
       ROW_NUMBER() OVER (PARTITION BY cc_call_center_sk ORDER BY order_cnt DESC) AS rn
   FROM (
      SELECT
          cc.cc_call_center_sk,
          sm.sm_ship_mode_id,
          COUNT(*) AS order_cnt
      FROM catalog_sales cs
      JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
      JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      GROUP BY cc.cc_call_center_sk, sm.sm_ship_mode_id
   ) t
)
SELECT
   cs.cc_name,
   cs.cc_division_name,
   cs.sm_ship_mode_id,
   cs.total_profit,
   cs.total_sales,
   cs.order_cnt,
   cs.avg_discount,
   cs.distinct_customers,
   CASE
      WHEN cs.total_profit > 1000000 THEN 'High Profit'
      WHEN cs.total_profit > 500000 THEN 'Medium Profit'
      ELSE 'Low Profit'
   END AS profit_category,
   RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank,
   CASE WHEN mpsm.rn = 1 THEN 'Most Used' ELSE '' END AS ship_mode_popularity
FROM call_center_sales cs
LEFT JOIN most_popular_ship_mode mpsm
   ON cs.cc_call_center_sk = mpsm.cc_call_center_sk
   AND cs.sm_ship_mode_id = mpsm.sm_ship_mode_id
WHERE cs.total_sales > 0
ORDER BY profit_rank
LIMIT 10
