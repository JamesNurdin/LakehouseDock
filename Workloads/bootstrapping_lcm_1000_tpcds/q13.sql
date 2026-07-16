SELECT
    d.d_year,
    (d.d_month_seq % 3) AS month_mod_3,
    sm.sm_type,
    hd_refunded.hd_buy_potential AS refunded_buy_potential,
    hd_returning.hd_buy_potential AS returning_buy_potential,
    CASE
        WHEN cr.cr_return_amount >= 200 THEN '>=200'
        WHEN cr.cr_return_amount >= 100 THEN '100-199'
        ELSE '<100'
    END AS return_amount_bucket,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN sm.sm_carrier = 'UPS' THEN cr.cr_return_amount ELSE 0 END) AS ups_return_amount,
    SUM(CASE WHEN sm.sm_carrier = 'FedEx' THEN cr.cr_return_amount ELSE 0 END) AS fedex_return_amount
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY
    d.d_year,
    (d.d_month_seq % 3),
    sm.sm_type,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_buy_potential,
    CASE
        WHEN cr.cr_return_amount >= 200 THEN '>=200'
        WHEN cr.cr_return_amount >= 100 THEN '100-199'
        ELSE '<100'
    END
HAVING COUNT(*) > 10
ORDER BY d.d_year, total_return_amount DESC
LIMIT 100
