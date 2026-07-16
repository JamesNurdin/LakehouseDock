WITH base AS (
    SELECT
        ib_ref.ib_lower_bound AS refunded_income_lower,
        ib_ref.ib_upper_bound AS refunded_income_upper,
        ib_ret.ib_lower_bound AS returning_income_lower,
        ib_ret.ib_upper_bound AS returning_income_upper,
        t.t_hour,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        AVG(hd_ret.hd_vehicle_count - hd_ref.hd_vehicle_count) AS avg_vehicle_count_diff,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
      ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib_ref
      ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    JOIN income_band ib_ret
      ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
    WHERE t.t_shift = 'Evening'
      AND t.t_hour BETWEEN 18 AND 23
    GROUP BY
        ib_ref.ib_lower_bound,
        ib_ref.ib_upper_bound,
        ib_ret.ib_lower_bound,
        ib_ret.ib_upper_bound,
        t.t_hour
    HAVING SUM(wr.wr_net_loss) > 1000
)
SELECT
    refunded_income_lower,
    refunded_income_upper,
    returning_income_lower,
    returning_income_upper,
    t_hour,
    total_net_loss,
    avg_return_qty,
    avg_vehicle_count_diff,
    return_cnt,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM base
ORDER BY total_net_loss DESC
LIMIT 50
