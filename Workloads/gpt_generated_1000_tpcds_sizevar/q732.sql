WITH
  sr_base AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_store_sk,
      sr.sr_cdemo_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_ticket_number,
      d.d_date,
      d.d_year,
      cd.cd_purchase_estimate,
      cd.cd_marital_status,
      cd.cd_dep_count,
      s.s_store_id,
      s.s_market_id,
      s.s_zip
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE cd.cd_purchase_estimate > 5000
      AND cd.cd_marital_status IN ('M', 'S')
      AND s.s_market_id IN (1, 5, 7)
      AND d.d_year = 2001
      AND sr.sr_return_quantity > 1
  ),
  wr_base AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_refunded_cdemo_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_order_number,
      d.d_date,
      d.d_year,
      cd.cd_purchase_estimate AS cd_ref_purchase_est,
      cd.cd_marital_status AS cd_ref_marital
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 5000
      AND d.d_year = 2001
      AND wr.wr_return_quantity > 0
  ),
  cp_base AS (
    SELECT
      cp.cp_catalog_page_id,
      cp.cp_department,
      cp.cp_type,
      cp.cp_start_date_sk,
      cp.cp_end_date_sk,
      d_start.d_date AS start_date,
      d_end.d_date AS end_date
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    WHERE cp.cp_department = 'Electronics'
      AND cp.cp_type = 'PROMO'
  )
SELECT
  sr.s_store_id,
  COALESCE(sr.d_year, wr.d_year) AS year,
  cp.cp_department,
  cp.cp_type,
  SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(wr.wr_return_amt, 0)) AS total_return_amt,
  COUNT(DISTINCT COALESCE(sr.sr_ticket_number, wr.wr_order_number)) AS return_transactions,
  RANK() OVER (PARTITION BY cp.cp_department ORDER BY SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(wr.wr_return_amt, 0)) DESC) AS dept_rank,
  (SELECT COUNT(*) FROM store s2 WHERE s2.s_market_id = 5) AS market_5_store_cnt
FROM sr_base sr
FULL OUTER JOIN wr_base wr
  ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
LEFT JOIN cp_base cp
  ON sr.sr_returned_date_sk = cp.cp_start_date_sk
WHERE (sr.cd_purchase_estimate IS NULL OR sr.cd_purchase_estimate > 6000)
  AND (wr.cd_ref_purchase_est IS NULL OR wr.cd_ref_purchase_est > 6000)
GROUP BY
  sr.s_store_id,
  COALESCE(sr.d_year, wr.d_year),
  cp.cp_department,
  cp.cp_type
HAVING SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(wr.wr_return_amt, 0)) > 15000
ORDER BY total_return_amt DESC
LIMIT 100
