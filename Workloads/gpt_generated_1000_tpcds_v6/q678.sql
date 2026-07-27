/* goal: Compare refund and return activity by time, loss status, and household characteristics using a UNION of two analytic sub‑queries */

WITH refunded AS (
    SELECT
        wr.wr_returned_date_sk AS return_date_key,
        td.t_hour AS hour_of_day,
        CASE WHEN wr.wr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_category,
        (
            SELECT COUNT(DISTINCT ib_sub.ib_income_band_sk)
            FROM household_demographics hd_sub
            JOIN income_band ib_sub ON hd_sub.hd_income_band_sk = ib_sub.ib_income_band_sk
            WHERE hd_sub.hd_demo_sk = c.c_current_hdemo_sk
        ) AS household_income_band_cnt
    FROM web_returns AS wr
    JOIN time_dim AS td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer AS c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 100000
),
returning AS (
    SELECT
        wr.wr_returned_date_sk AS return_date_key,
        td.t_hour AS hour_of_day,
        CASE WHEN wr.wr_return_quantity > 1 THEN 'Multiple' ELSE 'Single' END AS quantity_flag,
        (
            SELECT COUNT(DISTINCT ib_sub.ib_income_band_sk)
            FROM household_demographics hd_sub
            JOIN income_band ib_sub ON hd_sub.hd_income_band_sk = ib_sub.ib_income_band_sk
            WHERE hd_sub.hd_demo_sk = c_ret.c_current_hdemo_sk
        ) AS household_income_band_cnt
    FROM web_returns AS wr
    JOIN time_dim AS td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer AS c_ret ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
    JOIN household_demographics AS hd_ret ON c_ret.c_current_hdemo_sk = hd_ret.hd_demo_sk
    WHERE hd_ret.hd_vehicle_count >= 2
)
SELECT return_date_key,
       hour_of_day,
       loss_category AS metric,
       household_income_band_cnt
FROM refunded
UNION ALL
SELECT return_date_key,
       hour_of_day,
       quantity_flag AS metric,
       household_income_band_cnt
FROM returning
ORDER BY return_date_key DESC,
         metric
LIMIT 100
