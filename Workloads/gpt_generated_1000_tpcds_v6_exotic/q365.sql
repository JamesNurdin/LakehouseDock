WITH sales_agg AS (
  SELECT
    cc.cc_name,
    sm.sm_carrier,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_net_profit) AS avg_profit,
    COUNT(*) AS orders_cnt
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  WHERE sm.sm_carrier IN ('AIRBORNE', 'MSC')
    AND cc.cc_state = 'CA'
    AND cs.cs_coupon_amt > 500
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
  GROUP BY GROUPING SETS (
    (cc.cc_name, sm.sm_carrier),
    (cc.cc_name),
    ()
  )
)
SELECT
  cc_name,
  sm_carrier,
  total_profit,
  avg_profit,
  CASE WHEN total_profit > (SELECT AVG(cs_net_profit) FROM catalog_sales) THEN 'HIGH' ELSE 'LOW' END AS profit_category,
  RANK() OVER (PARTITION BY cc_name ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_rank, total_profit DESC
LIMIT 100
