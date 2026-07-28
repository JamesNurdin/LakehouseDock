SELECT *
FROM (
    SELECT
        sm.sm_ship_mode_id AS category_id,
        'ShipMode' AS category_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count,
        CASE
            WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HighLoss'
            WHEN SUM(cr.cr_net_loss) > 0 THEN 'LowLoss'
            ELSE 'NoLoss'
        END AS loss_category,
        ROW_NUMBER() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY SUM(cr.cr_return_amount) DESC) AS rn,
        (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS overall_avg_net_loss
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound > 50000
    GROUP BY sm.sm_ship_mode_id
    HAVING SUM(cr.cr_return_quantity) > 5

    UNION ALL

    SELECT
        r.r_reason_id AS category_id,
        'Reason' AS category_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count,
        CASE
            WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HighLoss'
            WHEN SUM(cr.cr_net_loss) > 0 THEN 'LowLoss'
            ELSE 'NoLoss'
        END AS loss_category,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_id ORDER BY SUM(cr.cr_return_amount) DESC) AS rn,
        (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS overall_avg_net_loss
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound <= 150000
      AND hd.hd_vehicle_count >= 0
    GROUP BY r.r_reason_id
    HAVING SUM(cr.cr_return_quantity) > 3
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
