WITH
  catalog_agg AS (
    SELECT
      cr_returned_date_sk,
      cr_reason_sk,
      cr_call_center_sk,
      cr_ship_mode_sk,
      cr_warehouse_sk,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(*) AS cr_cnt
    FROM catalog_returns
    WHERE cr_fee > 20.00
    GROUP BY cr_returned_date_sk, cr_reason_sk, cr_call_center_sk, cr_ship_mode_sk, cr_warehouse_sk
  ),
  store_agg AS (
    SELECT
      sr_returned_date_sk,
      sr_reason_sk,
      sr_cdemo_sk,
      SUM(sr_return_amt) AS total_store_return,
      COUNT(*) AS sr_cnt
    FROM store_returns
    WHERE sr_return_ship_cost > 30.00
    GROUP BY sr_returned_date_sk, sr_reason_sk, sr_cdemo_sk
  ),
  promo_subset AS (
    SELECT p_promo_sk, p_promo_id, p_start_date_sk, p_end_date_sk
    FROM promotion
    WHERE p_purpose = 'Unknown' AND p_discount_active = 'Y'
    LIMIT 5
  ),
  web_subset AS (
    SELECT wp_web_page_sk, wp_url, wp_creation_date_sk, wp_image_count
    FROM web_page
    WHERE wp_autogen_flag = 'Y' AND wp_image_count > 2
    LIMIT 5
  ),
  cross_pw AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_id,
      p.p_start_date_sk,
      p.p_end_date_sk,
      w.wp_web_page_sk,
      w.wp_url,
      w.wp_creation_date_sk
    FROM promo_subset p
    CROSS JOIN web_subset w
  ),
  full_join AS (
    SELECT
      COALESCE(ca.cr_returned_date_sk, sa.sr_returned_date_sk) AS return_date_sk,
      COALESCE(ca.cr_reason_sk, sa.sr_reason_sk) AS reason_sk,
      ca.total_return_amount,
      ca.cr_cnt,
      sa.total_store_return,
      sa.sr_cnt,
      ca.cr_call_center_sk,
      ca.cr_ship_mode_sk,
      ca.cr_warehouse_sk,
      sa.sr_cdemo_sk
    FROM catalog_agg ca
    FULL OUTER JOIN store_agg sa
      ON ca.cr_returned_date_sk = sa.sr_returned_date_sk
     AND ca.cr_reason_sk = sa.sr_reason_sk
  )
SELECT
  d.d_year,
  cc.cc_state,
  dm.cd_marital_status,
  r.r_reason_desc,
  CASE WHEN COALESCE(fj.total_return_amount, 0) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_category,
  SUM(COALESCE(fj.total_return_amount, 0)) AS sum_return_amount,
  SUM(COALESCE(fj.total_store_return, 0)) AS sum_store_return,
  COUNT(*) AS record_cnt,
  cp.p_promo_id,
  cp.wp_url
FROM full_join fj
JOIN date_dim d
  ON fj.return_date_sk = d.d_date_sk
JOIN reason r
  ON fj.reason_sk = r.r_reason_sk
LEFT JOIN call_center cc
  ON fj.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm
  ON fj.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
  ON fj.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN customer_demographics dm
  ON fj.sr_cdemo_sk = dm.cd_demo_sk
JOIN cross_pw cp
  ON d.d_date_sk BETWEEN cp.p_start_date_sk AND cp.p_end_date_sk
 AND d.d_date_sk = cp.wp_creation_date_sk
WHERE
  d.d_year = 2001
  AND cc.cc_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND w.w_country = 'United States'
  AND dm.cd_marital_status = 'M'
GROUP BY
  d.d_year,
  cc.cc_state,
  dm.cd_marital_status,
  r.r_reason_desc,
  CASE WHEN COALESCE(fj.total_return_amount, 0) > 1000 THEN 'HIGH' ELSE 'LOW' END,
  cp.p_promo_id,
  cp.wp_url
HAVING
  SUM(COALESCE(fj.total_return_amount, 0)) > 5000
ORDER BY sum_return_amount DESC
LIMIT 100
