SELECT cc.cc_name,
       cc.cc_city,
       SUM(cs.cs_net_profit) AS total_net_profit
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_zip = '47057'
  AND cs.cs_quantity > 5
GROUP BY cc.cc_name, cc.cc_city
