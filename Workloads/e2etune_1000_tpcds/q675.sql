WITH agg AS (
    SELECT
        hd_ret.hd_income_band_sk AS returning_income_band,
        hd_ret.hd_vehicle_count AS returning_vehicle_cnt,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        hd_ref.hd_income_band_sk AS refunded_income_band,
        hd_ref.hd_vehicle_count AS refunded_vehicle_cnt,
        hd_ref.hd_buy_potential AS refunded_buy_potential,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_fee) AS avg_return_fee,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_refunded_cash), 0) AS return_to_refund_ratio
    FROM catalog_returns cr
    JOIN household_demographics hd_ret
      ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref
      ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450926 AND 2451065
      AND cr.cr_reason_sk IN (17, 16, 59)
      AND cr.cr_call_center_sk = 19
    GROUP BY
        hd_ret.hd_income_band_sk,
        hd_ret.hd_vehicle_count,
        hd_ret.hd_buy_potential,
        hd_ref.hd_income_band_sk,
        hd_ref.hd_vehicle_count,
        hd_ref.hd_buy_potential
    HAVING COUNT(*) >= 5
)
SELECT
    returning_income_band,
    returning_vehicle_cnt,
    returning_buy_potential,
    refunded_income_band,
    refunded_vehicle_cnt,
    refunded_buy_potential,
    return_count,
    total_return_amount,
    avg_return_fee,
    total_net_loss,
    total_refunded_cash,
    return_to_refund_ratio,
    RANK() OVER (ORDER BY total_return_amount DESC) AS revenue_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
