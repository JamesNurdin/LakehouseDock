WITH sales_returns_agg AS (
   SELECT
       cc.cc_call_center_id,
       cc.cc_state,
       sm.sm_type,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cr.cr_return_amount) AS total_returns,
       SUM(cs.cs_net_profit) - SUM(cr.cr_return_amount) AS net_profit,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE cc.cc_tax_percentage BETWEEN 0.01 AND 0.12
     AND cc.cc_employees > 50000
     AND sm.sm_type IN ('REGULAR','EXPRESS')
     AND sm.sm_code = 'AIR'
     AND cs.cs_net_paid_inc_tax > 500
     AND cs.cs_ext_ship_cost < 1000
     AND cc.cc_state = 'CA'
   GROUP BY cc.cc_call_center_id, cc.cc_state, sm.sm_type
),

overall_avg AS (
   SELECT AVG(net_profit) AS avg_net_profit FROM sales_returns_agg
),

intersect_cc AS (
   SELECT cc.cc_call_center_id
   FROM call_center cc
   WHERE cc.cc_tax_percentage > 0.02
   INTERSECT
   SELECT cc.cc_call_center_id
   FROM call_center cc
   JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE cs.cs_net_paid_inc_tax > 1000
),

except_cc AS (
   SELECT cc.cc_call_center_id
   FROM call_center cc
   JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE cr.cr_return_amount > 0
   EXCEPT
   SELECT cc.cc_call_center_id
   FROM call_center cc
   WHERE cc.cc_employees < 100000
)
SELECT
   sra.cc_call_center_id,
   sra.cc_state,
   sra.sm_type,
   sra.total_sales,
   sra.total_returns,
   sra.net_profit,
   sra.order_cnt,
   (SELECT avg_net_profit FROM overall_avg) AS overall_avg_net_profit
FROM sales_returns_agg sra
WHERE sra.net_profit > (SELECT avg_net_profit FROM overall_avg)
  AND sra.cc_call_center_id IN (SELECT cc_call_center_id FROM intersect_cc)
  AND NOT EXISTS (SELECT 1 FROM except_cc ec WHERE ec.cc_call_center_id = sra.cc_call_center_id)
ORDER BY sra.net_profit DESC
LIMIT 100
