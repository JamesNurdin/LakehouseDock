SELECT cc.cc_name AS call_center_name,
       SUM(cs.cs_ext_sales_price) AS total_sales
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_state = 'NM'
  AND cs.cs_sold_date_sk = 2450826
GROUP BY cc.cc_name
