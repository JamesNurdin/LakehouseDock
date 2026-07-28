WITH
  store_info AS (
    SELECT
      s.s_store_sk,
      s.s_store_id,
      s.s_store_name,
      s.s_manager,
      s.s_market_manager,
      d.d_year,
      cc.cc_name,
      cp.cp_description
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    WHERE s.s_manager = 'Ricky Nichols'
      AND d.d_year = 2001
  ),
  sr_agg AS (
    SELECT
      sr.sr_store_sk,
      d.d_year,
      SUM(sr.sr_return_amt) AS sum_sr_return_amt,
      AVG(sr.sr_return_amt) AS avg_sr_return_amt,
      COUNT(*) AS cnt_sr,
      MIN(sr.sr_return_amt) AS min_sr_return_amt,
      MAX(sr.sr_return_amt) AS max_sr_return_amt,
      SUM(sr.sr_net_loss) AS sum_sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND sr.sr_return_amt > 500
      AND hd.hd_income_band_sk = 13
      AND sr.sr_return_quantity > 10
    GROUP BY sr.sr_store_sk, d.d_year
  ),
  wr_agg AS (
    SELECT
      d.d_year,
      SUM(wr.wr_return_amt) AS sum_wr_return_amt,
      AVG(wr.wr_return_amt) AS avg_wr_return_amt,
      COUNT(*) AS cnt_wr,
      MIN(wr.wr_return_amt) AS min_wr_return_amt,
      MAX(wr.wr_return_amt) AS max_wr_return_amt,
      SUM(wr.wr_net_loss) AS sum_wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND wr.wr_return_amt > 500
      AND hd.hd_income_band_sk = 13
    GROUP BY d.d_year
  )
SELECT
  si.s_store_id,
  si.s_store_name,
  si.s_manager,
  si.s_market_manager,
  si.d_year,
  si.cc_name AS call_center_name,
  si.cp_description AS catalog_page_desc,
  COALESCE(sr.sum_sr_return_amt, 0) AS total_store_return_amt,
  COALESCE(wr.sum_wr_return_amt, 0) AS total_web_return_amt,
  COALESCE(sr.sum_sr_return_amt, 0) + COALESCE(wr.sum_wr_return_amt, 0) AS total_combined_return_amt,
  CASE
    WHEN (COALESCE(sr.sum_sr_net_loss, 0) + COALESCE(wr.sum_wr_net_loss, 0)) > 10000 THEN 'HIGH'
    ELSE 'LOW'
  END AS loss_category,
  (SELECT SUM(sr2.sr_return_amt)
   FROM store_returns sr2
   JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
   WHERE d2.d_year = 2001) AS overall_year_return_amt
FROM store_info si
LEFT JOIN sr_agg sr ON sr.sr_store_sk = si.s_store_sk AND sr.d_year = si.d_year
LEFT JOIN wr_agg wr ON wr.d_year = si.d_year
ORDER BY total_combined_return_amt DESC
LIMIT 100
