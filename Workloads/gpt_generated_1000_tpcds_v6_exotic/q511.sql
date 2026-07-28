SELECT d.d_year,
       cc.cc_state,
       SUM(cs.cs_ext_sales_price)        AS total_sales,
       COUNT(*)                         AS order_cnt,
       AVG(cs.cs_net_profit)            AS avg_profit
FROM   catalog_sales cs
JOIN   call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN   date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
WHERE  d.d_year = 2001
  AND  cc.cc_state = 'CA'
  AND  cs.cs_ext_sales_price > 1000
  AND  EXISTS ( SELECT 1
                FROM   catalog_page cp
                WHERE  cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
                  AND  cp.cp_type = 'Web' )
GROUP BY d.d_year, cc.cc_state

UNION ALL

SELECT d.d_year,
       cc.cc_state,
       SUM(cs.cs_ext_sales_price)        AS total_sales,
       COUNT(*)                         AS order_cnt,
       AVG(cs.cs_net_profit)            AS avg_profit
FROM   catalog_sales cs
JOIN   call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN   date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
WHERE  d.d_year = 2002
  AND  cc.cc_state = 'CA'
  AND  cs.cs_ext_sales_price > 1000
  AND  EXISTS ( SELECT 1
                FROM   catalog_page cp
                WHERE  cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
                  AND  cp.cp_type = 'Web' )
GROUP BY d.d_year, cc.cc_state

LIMIT 100
