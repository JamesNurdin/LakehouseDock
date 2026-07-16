SELECT cc.cc_name,
       sm.sm_type,
       SUM(cs.cs_net_paid) AS total_net_paid,
       AVG(cs.cs_quantity) AS avg_quantity
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_sold_date_sk = 2450823 AND cc.cc_state = 'FL'
GROUP BY cc.cc_name, sm.sm_type
ORDER BY total_net_paid DESC
LIMIT 10
