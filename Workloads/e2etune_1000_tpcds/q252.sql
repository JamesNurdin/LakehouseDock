SELECT
    refunded_income_band_sk,
    refunded_income_lower,
    refunded_income_upper,
    returning_income_band_sk,
    returning_income_lower,
    returning_income_upper,
    total_return_amount,
    total_net_loss,
    avg_returning_vehicle_count,
    distinct_orders,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT
        ib_ref.ib_income_band_sk AS refunded_income_band_sk,
        ib_ref.ib_lower_bound AS refunded_income_lower,
        ib_ref.ib_upper_bound AS refunded_income_upper,
        ib_ret.ib_income_band_sk AS returning_income_band_sk,
        ib_ret.ib_lower_bound AS returning_income_lower,
        ib_ret.ib_upper_bound AS returning_income_upper,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(hd_ret.hd_vehicle_count) AS avg_returning_vehicle_count,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns wr
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib_ref
        ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib_ret
        ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
    WHERE hd_ret.hd_buy_potential = '5001-10000'
      AND hd_ret.hd_vehicle_count >= 2
      AND hd_ref.hd_buy_potential <> '0-500'
    GROUP BY
        ib_ref.ib_income_band_sk,
        ib_ref.ib_lower_bound,
        ib_ref.ib_upper_bound,
        ib_ret.ib_income_band_sk,
        ib_ret.ib_lower_bound,
        ib_ret.ib_upper_bound
) agg
ORDER BY total_net_loss DESC
LIMIT 100
