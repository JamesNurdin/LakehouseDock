/*
  Goal: Analyze store return performance by income band and household buying potential, focusing on returns with sizable quantities and amounts, while filtering for households with dependents and vehicles and income bands within a mid‑range.
*/
WITH filtered_returns AS (
    SELECT
        sr.sr_hdemo_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_store_credit,
        sr.sr_reversed_charge
    FROM tpcds.store_returns sr
    WHERE sr.sr_return_quantity > 1
      AND sr.sr_return_amt BETWEEN 10 AND 1000
      AND sr.sr_store_credit < 500
      AND sr.sr_reversed_charge > 0.5
      AND sr.sr_return_tax IS NOT NULL
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    COUNT(*) AS returns_cnt,
    SUM(fr.sr_return_amt) AS total_return_amt,
    AVG(fr.sr_return_amt) AS avg_return_amt,
    MIN(fr.sr_return_amt) AS min_return_amt,
    MAX(fr.sr_return_amt) AS max_return_amt,
    SUM(fr.sr_store_credit) AS total_store_credit
FROM filtered_returns fr
JOIN tpcds.household_demographics hd
    ON hd.hd_demo_sk = fr.sr_hdemo_sk
   AND hd.hd_dep_count >= 1
   AND hd.hd_vehicle_count >= 0
   AND hd.hd_buy_potential IN ('high', 'medium')
JOIN tpcds.income_band ib
    ON ib.ib_income_band_sk = hd.hd_income_band_sk
   AND ib.ib_lower_bound >= 50000
   AND ib.ib_upper_bound <= 150000
   AND EXISTS (
        SELECT 1
        FROM tpcds.income_band ib2
        WHERE ib2.ib_income_band_sk = ib.ib_income_band_sk
          AND (ib2.ib_upper_bound - ib2.ib_lower_bound) > 20000
   )
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential
ORDER BY total_return_amt DESC
LIMIT 100
