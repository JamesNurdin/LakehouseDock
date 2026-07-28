WITH high_sales AS (
  SELECT DISTINCT
    cc.cc_manager,
    cc.cc_state,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(cs.cs_net_paid_inc_tax) > 50000 THEN 'High' ELSE 'Low' END AS revenue_tier,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY SUM(cs.cs_net_paid_inc_tax) DESC) AS rn_state
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE cs.cs_net_paid_inc_tax > (
          SELECT AVG(cs2.cs_net_paid_inc_tax)
          FROM catalog_sales cs2
        )
    AND cc.cc_manager IN ('Charles Hinkle', 'Wayne Ray')
  GROUP BY cc.cc_manager, cc.cc_state
),
low_sales AS (
  SELECT DISTINCT
    cc.cc_manager,
    cc.cc_state,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(cs.cs_net_paid_inc_tax) > 20000 THEN 'Mid' ELSE 'Low' END AS revenue_tier,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY SUM(cs.cs_net_paid_inc_tax) DESC) AS rn_state
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE cs.cs_net_paid_inc_tax <= (
          SELECT AVG(cs2.cs_net_paid_inc_tax)
          FROM catalog_sales cs2
        )
    AND cc.cc_manager NOT IN ('Charles Hinkle', 'Wayne Ray')
  GROUP BY cc.cc_manager, cc.cc_state
)
SELECT *
FROM high_sales
UNION ALL
SELECT *
FROM low_sales
ORDER BY total_net_paid DESC
LIMIT 100
