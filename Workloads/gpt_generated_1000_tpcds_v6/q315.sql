SELECT
    cs.cs_order_number,
    cs.cs_sales_price,
    cs.cs_net_profit,
    cc.cc_name,
    cc.cc_city
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cs.cs_list_price > 100
  AND cc.cc_zip = '98048'
ORDER BY cs.cs_sales_price DESC
LIMIT 100
