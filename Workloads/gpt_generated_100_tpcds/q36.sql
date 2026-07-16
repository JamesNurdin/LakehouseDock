WITH aggregated_returns AS (
    SELECT
        ib_ref.ib_lower_bound AS refunded_income_lower,
        ib_ref.ib_upper_bound AS refunded_income_upper,
        hd_ref.hd_buy_potential AS refunded_buy_potential,
        ib_ret.ib_lower_bound AS returning_income_lower,
        ib_ret.ib_upper_bound AS returning_income_upper,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_fee) AS total_fee
    FROM catalog_returns cr
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib_ref
        ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib_ret
        ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
    GROUP BY
        ib_ref.ib_lower_bound,
        ib_ref.ib_upper_bound,
        hd_ref.hd_buy_potential,
        ib_ret.ib_lower_bound,
        ib_ret.ib_upper_bound,
        hd_ret.hd_buy_potential
)
SELECT
    refunded_income_lower,
    refunded_income_upper,
    refunded_buy_potential,
    returning_income_lower,
    returning_income_upper,
    returning_buy_potential,
    return_cnt,
    total_net_loss,
    avg_return_amount,
    avg_return_quantity,
    avg_return_tax,
    total_fee,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated_returns
ORDER BY total_net_loss DESC
LIMIT 50
