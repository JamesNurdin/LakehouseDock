WITH filtered_returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_reversed_charge,
        wr.wr_refunded_hdemo_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_returned_date_sk
    FROM web_returns wr
    WHERE wr.wr_return_amt > 50
      AND wr.wr_return_quantity BETWEEN 1 AND 5
      AND wr.wr_reversed_charge < 200
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
      AND wr.wr_return_tax IS NOT NULL
      AND wr.wr_fee IS NOT NULL
)
SELECT
    fr.wr_order_number,
    hd_refunded.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd_refunded.hd_vehicle_count,
    hd_refunded.hd_dep_count,
    fr.wr_return_amt,
    fr.wr_net_loss,
    CASE
        WHEN fr.wr_net_loss > 500 THEN 'High'
        WHEN fr.wr_net_loss > 200 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY fr.wr_net_loss DESC) AS rn_income_band,
    AVG(fr.wr_net_loss) OVER (PARTITION BY ib.ib_income_band_sk) AS avg_loss_income_band,
    (
        SELECT MAX(wr2.wr_net_loss)
        FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = fr.wr_returned_date_sk
    ) AS max_loss_same_date
FROM filtered_returns fr
JOIN household_demographics hd_refunded
    ON fr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON fr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN income_band ib
    ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd_refunded.hd_vehicle_count > 0
  AND hd_refunded.hd_dep_count <= 5
  AND ib.ib_upper_bound >= 20000
  AND hd_returning.hd_vehicle_count <> -1
  AND hd_returning.hd_dep_count >= 0
  AND ib.ib_income_band_sk IN (
        SELECT DISTINCT ib_income_band_sk
        FROM income_band
        WHERE ib_lower_bound >= 10000
    )
ORDER BY ib.ib_income_band_sk, rn_income_band
