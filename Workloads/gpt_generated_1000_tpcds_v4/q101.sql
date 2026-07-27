WITH refunded_agg AS (
    SELECT
        hd_refunded.hd_income_band_sk AS refunded_income_band,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        AVG(wr.wr_account_credit) AS avg_account_credit
    FROM tpcds.web_returns wr
    JOIN tpcds.household_demographics hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN tpcds.household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    WHERE hd_refunded.hd_dep_count >= 1
      AND hd_refunded.hd_vehicle_count >= 0
      AND hd_returning.hd_vehicle_count >= 1
      AND hd_returning.hd_income_band_sk BETWEEN 5 AND 15
      AND wr.wr_return_quantity BETWEEN 1 AND 5
      AND wr.wr_return_amt > 10
      AND wr.wr_account_credit < 400
      AND hd_refunded.hd_income_band_sk IN (1, 7, 10, 14, 16)
    GROUP BY hd_refunded.hd_income_band_sk
),
final_agg AS (
    SELECT
        refunded_income_band,
        total_return_amt,
        return_cnt,
        avg_return_qty,
        avg_account_credit,
        total_return_amt / NULLIF(return_cnt, 0) AS avg_return_per_txn
    FROM refunded_agg
    WHERE total_return_amt > 1000
)
SELECT
    refunded_income_band,
    SUM(total_return_amt) AS sum_return_amt,
    AVG(avg_return_per_txn) AS avg_return_per_txn_over_income,
    COUNT(*) AS num_income_groups
FROM final_agg
GROUP BY refunded_income_band
HAVING COUNT(*) >= 1
ORDER BY sum_return_amt DESC
LIMIT 100
