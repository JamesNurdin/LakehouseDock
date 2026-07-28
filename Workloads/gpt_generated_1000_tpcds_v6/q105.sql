WITH filtered_returns AS (
    SELECT sr.*
    FROM store_returns sr
    WHERE sr.sr_fee > 20
      AND sr.sr_return_quantity >= 2
      AND sr.sr_refunded_cash < 5000
      AND sr.sr_return_amt_inc_tax > 100
)
SELECT
    ib.ib_income_band_sk,
    hd.hd_buy_potential,
    COUNT(DISTINCT fr.sr_ticket_number) AS num_returns,
    SUM(fr.sr_return_amt) AS total_return_amt,
    AVG(fr.sr_fee) AS avg_fee,
    MIN(fr.sr_return_amt_inc_tax) AS min_return_inc_tax,
    MAX(fr.sr_return_amt_inc_tax) AS max_return_inc_tax
FROM filtered_returns fr
JOIN household_demographics hd
    ON fr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound >= 60000
  AND ib.ib_upper_bound <= 150000
  AND hd.hd_buy_potential = '5001-10000'
  AND NOT EXISTS (
        SELECT 1
        FROM income_band ib_ex
        WHERE ib_ex.ib_income_band_sk = hd.hd_income_band_sk
          AND ib_ex.ib_upper_bound < 80000
      )
GROUP BY ib.ib_income_band_sk, hd.hd_buy_potential
ORDER BY total_return_amt DESC
LIMIT 100
