WITH sr_filtered AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_hdemo_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_refunded_cash,
        sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_return_amt > 1000
      AND sr.sr_refunded_cash < 500
)
SELECT
    d.d_year,
    s.s_state,
    ib.ib_lower_bound,
    COUNT(*) AS return_cnt,
    SUM(sr_filtered.sr_return_amt) AS total_return_amt,
    AVG(sr_filtered.sr_refunded_cash) AS avg_refunded_cash,
    MIN(sr_filtered.sr_net_loss) AS min_net_loss,
    MAX(sr_filtered.sr_net_loss) AS max_net_loss
FROM sr_filtered
JOIN date_dim d ON sr_filtered.sr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd ON sr_filtered.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s ON sr_filtered.sr_store_sk = s.s_store_sk
WHERE d.d_year = 2002
  AND s.s_state = 'CA'
  AND ib.ib_lower_bound >= 50000
  AND EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = sr_filtered.sr_reason_sk
          AND r.r_reason_desc LIKE '%did not like%'
      )
GROUP BY d.d_year, s.s_state, ib.ib_lower_bound
ORDER BY total_return_amt DESC
LIMIT 100
