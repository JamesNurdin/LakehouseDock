WITH hourly_income AS (
    SELECT
        td.t_hour,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(wr.wr_return_amt)               AS sum_return_amt,
        COUNT(*)                             AS cnt_returns,
        COUNT(DISTINCT wr.wr_order_number)   AS distinct_orders
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    /* anti‑join: exclude returns whose receiving household has a vehicle count of -1 */
    WHERE NOT EXISTS (
        SELECT 1
        FROM household_demographics hd_ret
        WHERE hd_ret.hd_demo_sk = wr.wr_returning_hdemo_sk
          AND hd_ret.hd_vehicle_count = -1
    )
    AND td.t_hour IN (1, 7, 12)                     -- filter 1: specific hours
    AND hd_ref.hd_dep_count >= 2                    -- filter 2: households with at least 2 dependents
    AND ib.ib_upper_bound <= 50000                 -- filter 3: income band upper bound limit
    GROUP BY td.t_hour, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    hi.t_hour,
    AVG(hi.sum_return_amt) AS avg_sum_return_amt,
    SUM(hi.cnt_returns)    AS total_returns,
    COUNT(DISTINCT hi.ib_upper_bound) AS distinct_income_upper_bounds
FROM hourly_income hi
GROUP BY hi.t_hour
HAVING AVG(hi.sum_return_amt) > 1000            -- keep only hours with substantial average loss
ORDER BY avg_sum_return_amt DESC
LIMIT 100
