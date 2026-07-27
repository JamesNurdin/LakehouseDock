WITH wr_base AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_account_credit,
        wr.wr_refunded_hdemo_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_returning_addr_sk
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 1
      AND wr.wr_return_amt BETWEEN 10 AND 500
      AND wr.wr_account_credit < 500
)
SELECT
    wr.wr_returned_date_sk AS return_date_sk,
    t.t_hour,
    t.t_meal_time,
    hd_refunded.hd_demo_sk AS refunded_demo_sk,
    hd_refunded.hd_dep_count,
    hd_refunded.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    CASE
        WHEN wr.wr_return_amt >= 200 THEN 'High'
        WHEN wr.wr_return_amt >= 50  THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_category,
    ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY wr.wr_return_amt DESC) AS rn_income_band
FROM wr_base wr
JOIN time_dim t
  ON wr.wr_returned_time_sk = t.t_time_sk
JOIN household_demographics hd_refunded
  ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
  ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN income_band ib
  ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    hd_refunded.hd_dep_count BETWEEN 1 AND 8
    AND hd_refunded.hd_vehicle_count >= 0
    AND ib.ib_lower_bound >= 40000
    AND ib.ib_upper_bound <= 180000
    AND t.t_hour BETWEEN 9 AND 17
    AND t.t_meal_time = 'Lunch'
    AND wr.wr_return_amt > 20
    AND EXISTS (
        SELECT 1
        FROM income_band ib2
        WHERE ib2.ib_income_band_sk = hd_returning.hd_income_band_sk
          AND ib2.ib_upper_bound > 150000
    )
ORDER BY rn_income_band
LIMIT 100
