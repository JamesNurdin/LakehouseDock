SELECT
    cc.cc_name,
    cc.cc_city,
    cs.cs_order_number,
    cs.cs_net_paid_inc_tax
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_zip IN ('41933', '28482')
  AND cs.cs_net_paid_inc_tax > 1000
LIMIT 100
