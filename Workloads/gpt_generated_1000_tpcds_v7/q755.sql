WITH grouped AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        c.c_birth_month,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_tax) AS avg_return_tax,
        COUNT(*) AS returns_cnt,
        MIN(wr.wr_return_amt_inc_tax) AS min_return_amt_inc_tax,
        MAX(wr.wr_fee) AS max_fee
    FROM web_returns wr
    JOIN customer c
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count > 1
      AND c.c_birth_month = 6
      AND wr.wr_reversed_charge > 20
      AND wr.wr_return_quantity > 1
    GROUP BY hd.hd_income_band_sk, hd.hd_vehicle_count, c.c_birth_month
)
SELECT
    hd_income_band_sk,
    hd_vehicle_count,
    c_birth_month,
    total_return_amt,
    avg_return_tax,
    returns_cnt,
    min_return_amt_inc_tax,
    max_fee,
    SUM(total_return_amt) OVER (PARTITION BY hd_income_band_sk ORDER BY hd_vehicle_count ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt,
    RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_return_amt DESC) AS return_amt_rank
FROM grouped
ORDER BY hd_income_band_sk, hd_vehicle_count
