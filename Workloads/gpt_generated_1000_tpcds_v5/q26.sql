WITH ship_stats AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amount > 100
      AND sm.sm_type IN ('REGULAR', 'EXPRESS')
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
),
filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        sm.sm_type,
        sm.sm_contract,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        ca.ca_state,
        CASE WHEN cr.cr_net_loss > 200 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
        ROW_NUMBER() OVER (PARTITION BY sm.sm_type ORDER BY cr.cr_return_amount DESC) AS rn,
        (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_ship_mode_sk = cr.cr_ship_mode_sk
        ) AS ship_mode_avg_return
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE sm.sm_contract = 'Ek'
      AND hd.hd_income_band_sk BETWEEN 10 AND 20
      AND ca.ca_state = 'CA'
      AND cr.cr_reason_sk IN (52, 38, 56, 9, 51)
)
SELECT DISTINCT
    fr.cr_order_number,
    fr.cr_return_amount,
    fr.cr_net_loss,
    fr.loss_category,
    fr.sm_type,
    fr.sm_contract,
    fr.hd_income_band_sk,
    fr.hd_dep_count,
    fr.ca_state,
    fr.rn,
    ss.total_returns,
    ss.total_return_amount,
    ss.avg_return_amount,
    fr.ship_mode_avg_return
FROM filtered_returns fr
JOIN ship_stats ss ON fr.sm_type = ss.sm_type
WHERE fr.rn <= 5
ORDER BY fr.sm_type, fr.rn
LIMIT 100
