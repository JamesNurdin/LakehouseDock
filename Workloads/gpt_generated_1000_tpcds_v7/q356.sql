WITH catalog_data AS (
    SELECT
        r.r_reason_desc AS reason,
        t.t_hour AS hour,
        cr.cr_return_amt_inc_tax AS amount,
        'Catalog' AS source
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound > 50000
),
web_data AS (
    SELECT
        r.r_reason_desc AS reason,
        t.t_hour AS hour,
        wr.wr_return_amt_inc_tax AS amount,
        'Web' AS source
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound > 50000
)
SELECT
    reason,
    hour,
    source,
    SUM(amount) AS total_return_amount
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM web_data
) u
GROUP BY reason, hour, source
ORDER BY reason, hour, source
