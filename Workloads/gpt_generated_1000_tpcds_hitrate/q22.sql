WITH joined AS (
    SELECT
        wr.wr_return_amt,
        wr.wr_refunded_cash,
        wr.wr_reason_sk,
        wr.wr_return_quantity,
        hd_refunded.hd_demo_sk AS refunded_demo_sk,
        hd_refunded.hd_income_band_sk AS refunded_income_band_sk,
        hd_refunded.hd_dep_count AS refunded_dep_count,
        hd_refunded.hd_vehicle_count AS refunded_vehicle_count,
        hd_returning.hd_demo_sk AS returning_demo_sk,
        hd_returning.hd_income_band_sk AS returning_income_band_sk,
        hd_returning.hd_dep_count AS returning_dep_count,
        hd_returning.hd_vehicle_count AS returning_vehicle_count
    FROM web_returns wr
    JOIN household_demographics hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    WHERE hd_refunded.hd_dep_count >= 1
      AND hd_returning.hd_vehicle_count BETWEEN 1 AND 3
      AND wr.wr_reason_sk IN (5, 23, 27)
      AND wr.wr_refunded_cash > 100
),
agg AS (
    SELECT
        refunded_income_band_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM joined
    GROUP BY refunded_income_band_sk
)
SELECT
    refunded_income_band_sk,
    total_return_amt,
    return_cnt,
    CASE
        WHEN total_return_amt > 500 THEN 'High'
        ELSE 'Low'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY refunded_income_band_sk ORDER BY total_return_amt DESC) AS row_num
FROM agg
ORDER BY row_num
LIMIT 100
