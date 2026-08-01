WITH ws_agg AS (
   SELECT
       ws_warehouse_sk,
       ws_ship_mode_sk,
       ws_bill_cdemo_sk,
       ws_web_page_sk,
       SUM(ws_ext_sales_price) AS total_sales,
       SUM(ws_net_profit) AS total_profit,
       COUNT(*) AS order_cnt
   FROM web_sales
   WHERE ws_sales_price > 30.0
     AND ws_coupon_amt < 500.0
   GROUP BY ws_warehouse_sk, ws_ship_mode_sk, ws_bill_cdemo_sk, ws_web_page_sk
),
excluded_warehouses AS (
   SELECT w_warehouse_id
   FROM warehouse
   WHERE w_state = 'TX'
   EXCEPT
   SELECT w_warehouse_id
   FROM warehouse
   WHERE w_zip = '64593'
)
SELECT
   w.w_state,
   sm.sm_type,
   cd.cd_gender,
   SUM(ws.total_sales) AS sum_sales,
   SUM(ws.total_profit) AS sum_profit,
   SUM(ws.order_cnt) AS total_orders
FROM ws_agg ws
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE cd.cd_purchase_estimate >= 6500
  AND cd.cd_dep_college_count >= 3
  AND w.w_zip = '64593'
  AND sm.sm_type = 'AIR'
  AND wp.wp_type = 'Content'
  AND w.w_warehouse_sk NOT IN (SELECT ws_warehouse_sk FROM web_sales WHERE ws_coupon_amt > 5000)
  AND w.w_warehouse_id NOT IN (SELECT w_warehouse_id FROM excluded_warehouses)
GROUP BY ROLLUP (w.w_state, sm.sm_type, cd.cd_gender)
ORDER BY w.w_state ASC, sm.sm_type ASC, cd.cd_gender ASC
LIMIT 100
