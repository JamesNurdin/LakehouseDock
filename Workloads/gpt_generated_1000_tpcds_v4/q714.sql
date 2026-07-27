SELECT
  cc.cc_city,
  SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax
FROM
  catalog_sales cs
JOIN
  call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE
  cc.cc_city = 'Spring Hill'
  AND cs.cs_net_paid_inc_ship_tax > 2000
GROUP BY
  cc.cc_city
ORDER BY
  total_net_paid_inc_ship_tax DESC
