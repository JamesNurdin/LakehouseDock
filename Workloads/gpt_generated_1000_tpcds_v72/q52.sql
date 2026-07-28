SELECT cc.cc_name,
       cc.cc_country,
       SUM(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_country = 'United States'
  AND cs.cs_ext_tax > 20
GROUP BY cc.cc_name, cc.cc_country
ORDER BY total_net_paid DESC
LIMIT 100
