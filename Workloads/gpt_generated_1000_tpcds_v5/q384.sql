WITH
  catalog_agg AS (
    SELECT
      cr.cr_catalog_page_sk,
      cr.cr_reason_sk,
      SUM(cr.cr_return_amount) AS sum_cr_return_amount,
      AVG(cr.cr_return_amt_inc_tax) AS avg_cr_return_inc_tax,
      COUNT(*) AS cnt_cr
    FROM tpcds.catalog_returns cr
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_refunded_cdemo_sk IN (1211671, 1141354)
      AND cr.cr_store_credit > 50
      AND cr.cr_return_amt_inc_tax BETWEEN 20 AND 2000
    GROUP BY cr.cr_catalog_page_sk, cr.cr_reason_sk
  ),
  store_agg AS (
    SELECT
      sr.sr_reason_sk,
      SUM(sr.sr_return_amt) AS sum_sr_return_amt,
      COUNT(*) AS cnt_sr
    FROM tpcds.store_returns sr
    WHERE sr.sr_return_quantity > 1
      AND sr.sr_return_tax < 100
    GROUP BY sr.sr_reason_sk
  ),
  web_agg AS (
    SELECT
      wr.wr_reason_sk,
      SUM(wr.wr_refunded_cash) AS sum_wr_refunded_cash,
      AVG(wr.wr_fee) AS avg_wr_fee,
      COUNT(*) AS cnt_wr
    FROM tpcds.web_returns wr
    WHERE wr.wr_fee < 100
      AND wr.wr_return_tax >= 10
      AND wr.wr_refunded_cash > 0
    GROUP BY wr.wr_reason_sk
  )
SELECT
  cp.cp_department,
  cp.cp_type,
  r.r_reason_desc,
  COALESCE(ca.sum_cr_return_amount, 0) AS total_catalog_return_amount,
  COALESCE(sa.sum_sr_return_amt, 0) AS total_store_return_amount,
  COALESCE(wa.sum_wr_refunded_cash, 0) AS total_web_refunded_cash,
  (COALESCE(ca.cnt_cr, 0) + COALESCE(sa.cnt_sr, 0) + COALESCE(wa.cnt_wr, 0)) AS total_return_events,
  ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY COALESCE(ca.sum_cr_return_amount, 0) DESC) AS reason_rank
FROM tpcds.catalog_page cp
LEFT JOIN catalog_agg ca ON ca.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN tpcds.reason r ON r.r_reason_sk = ca.cr_reason_sk
LEFT JOIN store_agg sa ON sa.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_agg wa ON wa.wr_reason_sk = r.r_reason_sk
WHERE r.r_reason_id = 'AAAAAAAAAHAAAAAAA'
  AND cp.cp_department = 'Electronics'
  AND cp.cp_type = 'PROMO'
ORDER BY total_catalog_return_amount DESC
LIMIT 100
