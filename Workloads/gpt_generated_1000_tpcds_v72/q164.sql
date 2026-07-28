WITH
  sales_agg AS (
    SELECT
      ss_sold_time_sk,
      ss_store_sk,
      SUM(ss_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_coupon_amt > 100
    GROUP BY ss_sold_time_sk, ss_store_sk
  ),
  union_data AS (
    SELECT
      sa.ss_sold_time_sk,
      sa.ss_store_sk,
      td.t_hour,
      cc.cc_division,
      cr.cr_return_amount,
      sm.sm_type,
      w.w_country,
      r.r_reason_desc,
      sa.total_net_paid,
      sa.sales_cnt
    FROM sales_agg sa
    JOIN time_dim td ON sa.ss_sold_time_sk = td.t_time_sk
    JOIN catalog_returns cr ON td.t_time_sk = cr.cr_returned_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_division = 2
      AND w.w_country = 'United States'
      AND sm.sm_type = 'AIR'
      AND td.t_hour BETWEEN 9 AND 17
      AND r.r_reason_desc LIKE '%damaged%'

    UNION ALL

    SELECT
      sa.ss_sold_time_sk,
      sa.ss_store_sk,
      td.t_hour,
      cc.cc_division,
      cr.cr_return_amount,
      sm.sm_type,
      w.w_country,
      r.r_reason_desc,
      sa.total_net_paid,
      sa.sales_cnt
    FROM sales_agg sa
    JOIN time_dim td ON sa.ss_sold_time_sk = td.t_time_sk
    JOIN catalog_returns cr ON td.t_time_sk = cr.cr_returned_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_division = 3
      AND w.w_country = 'Canada'
      AND sm.sm_type = 'GROUND'
      AND td.t_hour BETWEEN 0 AND 8
      AND r.r_reason_desc LIKE '%not working%'
  )
SELECT
  ud.t_hour,
  ud.cc_division,
  ud.sm_type,
  SUM(ud.total_net_paid) AS sum_net_paid,
  SUM(ud.cr_return_amount) AS sum_return_amount,
  COUNT(DISTINCT ud.ss_store_sk) AS distinct_store_cnt,
  MAX((SELECT COUNT(*) FROM catalog_page cp WHERE cp.cp_type = ud.sm_type)) AS page_type_cnt
FROM union_data ud
WHERE EXISTS (
        SELECT 1
        FROM call_center cc2
        WHERE cc2.cc_division = ud.cc_division
          AND cc2.cc_mkt_desc LIKE 'Blue%'
      )
  AND ud.r_reason_desc IN (
        SELECT r2.r_reason_desc
        FROM reason r2
        WHERE r2.r_reason_desc LIKE '%damaged%' OR r2.r_reason_desc LIKE '%not working%'
      )
GROUP BY ud.t_hour, ud.cc_division, ud.sm_type
HAVING SUM(ud.total_net_paid) > 5000
ORDER BY sum_net_paid DESC
LIMIT 100
