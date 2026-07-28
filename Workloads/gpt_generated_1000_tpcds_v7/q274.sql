WITH sr AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    r.r_reason_desc,
    SUM(sr.sr_return_amt) AS store_return_total,
    COUNT(*) AS store_return_cnt
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE s.s_country = 'United States'
    AND r.r_reason_desc LIKE '%damaged%'
    AND s.s_rec_start_date >= DATE '1999-01-01'
  GROUP BY s.s_store_id, s.s_store_name, r.r_reason_desc
),
cr AS (
  SELECT
    cc.cc_call_center_id,
    sm.sm_type,
    r.r_reason_desc,
    SUM(cr.cr_return_amount) AS catalog_return_total,
    COUNT(*) AS catalog_return_cnt
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cc.cc_state = 'CA'
    AND r.r_reason_desc LIKE '%damaged%'
    AND cc.cc_rec_start_date >= DATE '1999-01-01'
  GROUP BY cc.cc_call_center_id, sm.sm_type, r.r_reason_desc
),
wr AS (
  SELECT
    r.r_reason_desc,
    SUM(wr.wr_return_amt) AS web_return_total,
    COUNT(*) AS web_return_cnt
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE r.r_reason_desc LIKE '%damaged%'
  GROUP BY r.r_reason_desc
)
SELECT
  sr.s_store_id,
  sr.s_store_name,
  sr.r_reason_desc,
  sr.store_return_total,
  cr.catalog_return_total,
  wr.web_return_total,
  (sr.store_return_total + COALESCE(cr.catalog_return_total, 0) + COALESCE(wr.web_return_total, 0)) AS total_return_amount,
  sr.store_return_cnt + COALESCE(cr.catalog_return_cnt, 0) + COALESCE(wr.web_return_cnt, 0) AS total_return_cnt
FROM sr
LEFT JOIN cr ON cr.r_reason_desc = sr.r_reason_desc
LEFT JOIN wr ON wr.r_reason_desc = sr.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
