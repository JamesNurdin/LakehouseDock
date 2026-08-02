SELECT cc.cc_name,
       cc.cc_city,
       sum(cs.cs_net_paid_inc_ship_tax) AS total_net_paid
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_company_name = 'pri'
  AND cs.cs_net_paid_inc_ship_tax > 3000
GROUP BY cc.cc_name, cc.cc_city
ORDER BY total_net_paid DESC
