WITH refunded AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        hd.hd_income_band_sk AS income_band,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        (SELECT AVG(wr2.wr_fee)
         FROM web_returns wr2
         WHERE wr2.wr_reason_sk = r.r_reason_sk) AS avg_fee
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE r.r_reason_id LIKE 'AAAAAAA%'
      AND hd.hd_vehicle_count >= 0
    GROUP BY r.r_reason_desc, hd.hd_income_band_sk, r.r_reason_sk
),
returning AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        hd.hd_income_band_sk AS income_band,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        (SELECT AVG(wr2.wr_fee)
         FROM web_returns wr2
         WHERE wr2.wr_reason_sk = r.r_reason_sk) AS avg_fee
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE r.r_reason_desc LIKE '%product%'
      AND hd.hd_income_band_sk BETWEEN 5 AND 15
    GROUP BY r.r_reason_desc, hd.hd_income_band_sk, r.r_reason_sk
),
combined AS (
    SELECT reason_desc, income_band, total_return_amt, return_cnt, avg_fee FROM refunded
    UNION ALL
    SELECT reason_desc, income_band, total_return_amt, return_cnt, avg_fee FROM returning
)
SELECT DISTINCT
    reason_desc,
    income_band,
    total_return_amt,
    return_cnt,
    avg_fee
FROM combined
ORDER BY total_return_amt DESC
LIMIT 100
