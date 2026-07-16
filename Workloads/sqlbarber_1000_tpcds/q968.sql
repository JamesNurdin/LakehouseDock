SELECT cc.cc_name,
       SUM(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_state = 'GA'
GROUP BY cc.cc_name
