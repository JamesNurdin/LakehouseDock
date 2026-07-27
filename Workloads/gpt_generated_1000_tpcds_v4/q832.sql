WITH overall_avg AS (
    SELECT AVG(sr_return_amt) AS avg_amt
    FROM tpcds.store_returns
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    MIN(sr.sr_return_amt) AS min_return_amt,
    MAX(sr.sr_return_amt) AS max_return_amt,
    SUM(CASE WHEN sr.sr_store_credit > 500 THEN sr.sr_store_credit ELSE 0 END) AS high_store_credit_sum,
    SUM(CASE 
            WHEN sr.sr_return_amt > (SELECT avg_amt FROM overall_avg) THEN 1
            ELSE 0
        END) AS cnt_above_overall_avg
FROM tpcds.store_returns sr
JOIN tpcds.household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound >= 40000
  AND ib.ib_upper_bound <= 200000
  AND hd.hd_vehicle_count <= 2
  AND hd.hd_dep_count >= 3
  AND hd.hd_buy_potential IN ('>10000', '5001-10000')
  AND sr.sr_store_credit > 100
  AND sr.sr_return_amt BETWEEN 10 AND 1000
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr2
        WHERE sr2.sr_hdemo_sk = sr.sr_hdemo_sk
          AND sr2.sr_return_amt > 500
        LIMIT 1
      )
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
ORDER BY total_return_amt DESC
LIMIT 100
