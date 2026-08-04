WITH sales_agg AS (
   SELECT
       cc.cc_call_center_id,
       sm.sm_code,
       w.w_warehouse_name,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
       CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE cs.cs_coupon_amt > 500
     AND cs.cs_list_price BETWEEN 20 AND 150
     AND sm.sm_carrier IN ('ALLIANCE', 'MSC')
   GROUP BY cc.cc_call_center_id, sm.sm_code, w.w_warehouse_name
),
high_sales AS (
   SELECT DISTINCT cc_call_center_id, sales_category
   FROM sales_agg
   WHERE sales_category = 'HIGH'
),
profit_sales AS (
   SELECT cc_call_center_id, sales_category
   FROM sales_agg
   WHERE total_profit > 5000
)
SELECT
   hs.cc_call_center_id,
   hs.sales_category,
   COUNT(*) OVER (PARTITION BY hs.sales_category) AS cnt_per_category
FROM (
   SELECT * FROM high_sales
   INTERSECT
   SELECT * FROM profit_sales
) AS hs
ORDER BY hs.cc_call_center_id
LIMIT 100
