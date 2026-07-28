WITH high_vehicle AS (
    SELECT
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        CAST('high_vehicle' AS VARCHAR) AS segment
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 3
    GROUP BY sr.sr_store_sk
),
low_income AS (
    SELECT
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        CAST('low_income' AS VARCHAR) AS segment
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk <= 5
    GROUP BY sr.sr_store_sk
)
SELECT
    high_vehicle.sr_store_sk,
    high_vehicle.total_return_amt,
    high_vehicle.segment
FROM high_vehicle
UNION ALL
SELECT
    low_income.sr_store_sk,
    low_income.total_return_amt,
    low_income.segment
FROM low_income
ORDER BY total_return_amt DESC
LIMIT 20
