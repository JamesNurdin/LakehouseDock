WITH cs_agg AS (
  SELECT
    cc.cc_name,
    p.p_promo_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(*) AS num_orders,
    AVG(cs.cs_quantity) AS avg_quantity
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cc.cc_class = 'medium'
    AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
    AND p.p_channel_dmail = 'Y'
    AND p.p_channel_email = 'N'
    AND cd.cd_marital_status IN ('M', 'S')
    AND sm.sm_type = 'AIR'
  GROUP BY cc.cc_name, p.p_promo_name
  HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT
  cc_name,
  p_promo_name,
  total_net_paid,
  num_orders,
  avg_quantity,
  LAG(total_net_paid) OVER (PARTITION BY cc_name ORDER BY total_net_paid DESC) AS prev_total_net_paid
FROM cs_agg
ORDER BY total_net_paid DESC
LIMIT 100
