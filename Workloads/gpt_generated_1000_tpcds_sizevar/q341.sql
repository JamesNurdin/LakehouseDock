WITH
  sales_monthly AS (
    SELECT
      cc.cc_call_center_id,
      cc.cc_company_name,
      SUM(cs.cs_net_paid_inc_ship) AS total_paid,
      COUNT(cs.cs_order_number) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_gmt_offset = -6.00
      AND cp.cp_type = 'monthly'
    GROUP BY cc.cc_call_center_id, cc.cc_company_name
  ),
  sales_quarterly AS (
    SELECT
      cc.cc_call_center_id,
      cc.cc_company_name,
      SUM(cs.cs_net_paid_inc_ship) AS total_paid,
      COUNT(cs.cs_order_number) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_gmt_offset = -8.00
      AND cp.cp_type = 'quarterly'
    GROUP BY cc.cc_call_center_id, cc.cc_company_name
  )
SELECT
  u.cc_call_center_id,
  u.cc_company_name,
  u.total_paid,
  u.order_cnt,
  LAG(u.total_paid) OVER (PARTITION BY u.cc_company_name ORDER BY u.total_paid DESC) AS prev_total_paid
FROM (
  SELECT * FROM sales_monthly
  UNION ALL
  SELECT * FROM sales_quarterly
) u
ORDER BY u.total_paid DESC
LIMIT 100
