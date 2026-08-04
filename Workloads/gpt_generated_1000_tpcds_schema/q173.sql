WITH sales_agg AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_company_name,
    w.w_city,
    cp.cp_department,
    td.t_shift,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_paid,
    AVG(cs.cs_quantity) AS avg_quantity
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE cc.cc_state = 'CA'
    AND w.w_state = 'CA'
    AND cp.cp_catalog_number IN (4, 10, 17)
    AND td.t_hour BETWEEN 9 AND 17
    AND cs.cs_net_paid_inc_ship_tax > 1000
  GROUP BY
    cc.cc_call_center_sk,
    cc.cc_company_name,
    w.w_city,
    cp.cp_department,
    td.t_shift
)
SELECT
  sa.cc_company_name,
  sa.w_city,
  sa.cp_department,
  sa.t_shift,
  sa.total_paid,
  sa.avg_quantity,
  (
    SELECT COUNT(*)
    FROM catalog_sales cs2
    WHERE cs2.cs_call_center_sk = sa.cc_call_center_sk
      AND cs2.cs_net_paid_inc_ship_tax > 500
  ) AS high_value_sales_cnt
FROM sales_agg sa
ORDER BY sa.total_paid DESC
LIMIT 100
