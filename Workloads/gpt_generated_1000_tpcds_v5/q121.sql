WITH overall AS (
    SELECT avg(wr_return_amt) AS overall_avg_return_amt
    FROM tpcds.web_returns
)
SELECT hd_income_band_sk,
       total_returns,
       avg_return_amt,
       overall_avg_return_amt
FROM (
    SELECT 
        hd.hd_income_band_sk,
        count(*) AS total_returns,
        avg(wr.wr_return_amt) AS avg_return_amt,
        (SELECT overall_avg_return_amt FROM overall) AS overall_avg_return_amt
    FROM tpcds.web_returns wr
    JOIN tpcds.household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 1
      AND hd.hd_dep_count <= 2
      AND wr.wr_refunded_cash > 100
    GROUP BY hd.hd_income_band_sk

    UNION ALL

    SELECT 
        hd.hd_income_band_sk,
        count(*) AS total_returns,
        avg(wr.wr_return_amt) AS avg_return_amt,
        (SELECT overall_avg_return_amt FROM overall) AS overall_avg_return_amt
    FROM tpcds.web_returns wr
    JOIN tpcds.household_demographics hd
        ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk BETWEEN 10 AND 20
      AND wr.wr_return_quantity > 1
      AND wr.wr_return_tax > 5
    GROUP BY hd.hd_income_band_sk
) AS u
ORDER BY avg_return_amt DESC
LIMIT 100
