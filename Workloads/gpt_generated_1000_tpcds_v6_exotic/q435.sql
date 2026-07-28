WITH catalog_agg AS (
  SELECT
    cp.cp_department,
    sm.sm_type,
    NULL AS wp_type,
    cr.cr_return_amount AS return_amount,
    cr.cr_return_quantity AS return_qty,
    r.r_reason_desc AS reason_desc
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE cp.cp_start_date_sk BETWEEN 2450845 AND 2451271
    AND sm.sm_code IN ('AIR','SEA')
    AND hd.hd_vehicle_count > 1
    AND hd.hd_income_band_sk IN (3,4,5)
),
web_agg AS (
  SELECT
    NULL AS cp_department,
    NULL AS sm_type,
    wp.wp_type,
    wr.wr_return_amt AS return_amount,
    wr.wr_return_quantity AS return_qty,
    r.r_reason_desc AS reason_desc
  FROM web_returns wr
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE wp.wp_autogen_flag = 'Y'
    AND wp.wp_max_ad_count >= 2
    AND hd.hd_dep_count = 0
    AND hd.hd_income_band_sk = 2
),
combined AS (
  SELECT cp_department, sm_type, wp_type, return_amount, return_qty, reason_desc FROM catalog_agg
  UNION ALL
  SELECT cp_department, sm_type, wp_type, return_amount, return_qty, reason_desc FROM web_agg
)
SELECT
  COALESCE(cp_department, 'ALL_DEPT') AS department,
  COALESCE(sm_type, 'ALL_MODE') AS ship_mode_type,
  COALESCE(wp_type, 'ALL_WEB_TYPE') AS web_page_type,
  COUNT(*) AS return_rows,
  SUM(return_amount) AS total_return_amount,
  SUM(return_qty) AS total_quantity,
  AVG(return_amount) AS avg_return_amount
FROM combined
GROUP BY ROLLUP(cp_department, sm_type, wp_type)
HAVING SUM(return_amount) > 1000
ORDER BY department, ship_mode_type, web_page_type
LIMIT 100
