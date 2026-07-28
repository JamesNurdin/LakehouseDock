WITH mode_agg AS (
    SELECT
        sm.sm_ship_mode_id AS sm_id,
        sm.sm_code AS sm_code,
        COUNT(cr.cr_order_number) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_ret_amount,
        AVG(cr.cr_return_tax) AS avg_ret_tax,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        cr.cr_return_quantity > 1
        AND cr.cr_return_amount >= 10.00
        AND cr.cr_reversed_charge < 1000.00
        AND cr.cr_net_loss BETWEEN 100 AND 2000
        AND sm.sm_ship_mode_id LIKE 'AAAAAAA%'
        AND sm.sm_contract IN ('HVDFCcQ','yVfotg7Tio3MVhBg6Bkn')
    GROUP BY
        sm.sm_ship_mode_id,
        sm.sm_code
),
mode_ranked AS (
    SELECT
        sm_id,
        sm_code,
        return_cnt,
        total_ret_amount,
        avg_ret_tax,
        total_net_loss,
        ROW_NUMBER() OVER (ORDER BY total_ret_amount DESC) AS rn
    FROM mode_agg
    WHERE total_ret_amount > 5000
)
SELECT
    sm_code,
    COUNT(*) AS mode_count,
    SUM(total_ret_amount) AS sum_ret_amount,
    AVG(avg_ret_tax) AS avg_tax_across_modes
FROM mode_ranked
WHERE rn <= 100
GROUP BY sm_code
ORDER BY sum_ret_amount DESC
LIMIT 100
