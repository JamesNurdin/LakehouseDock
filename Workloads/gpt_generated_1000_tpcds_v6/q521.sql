WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_net_loss,
        td.t_hour,
        hd.hd_buy_potential,
        ib.ib_upper_bound
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td.t_minute IN (1, 4, 6)
      AND td.t_time >= 8
      AND hd.hd_vehicle_count >= 0
      AND hd.hd_buy_potential = '>10000'
      AND ib.ib_lower_bound >= 30000
      AND cr.cr_fee > 20
)
SELECT
    t_hour,
    hd_buy_potential,
    ib_upper_bound,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_fee) AS avg_fee,
    COUNT(*) AS return_cnt,
    MAX(cr_net_loss) AS max_net_loss,
    SUM(CASE WHEN cr_return_amount > 1000 THEN 1 ELSE 0 END) AS high_return_cnt
FROM filtered
GROUP BY t_hour, hd_buy_potential, ib_upper_bound
ORDER BY total_return_amount DESC
LIMIT 100
