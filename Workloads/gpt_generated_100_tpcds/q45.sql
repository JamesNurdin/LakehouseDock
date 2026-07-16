WITH refunded AS (
    SELECT
        'refunded' AS role,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
),
returning AS (
    SELECT
        'returning' AS role,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
)
SELECT
    role,
    hd_income_band_sk,
    hd_buy_potential,
    COUNT(*) AS return_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_quantity) AS avg_return_quantity,
    CASE WHEN SUM(cr_return_amount) = 0 THEN NULL
         ELSE SUM(cr_net_loss) / SUM(cr_return_amount)
    END AS net_loss_to_return_ratio
FROM (
    SELECT role, hd_income_band_sk, hd_buy_potential, cr_return_amount, cr_net_loss, cr_return_quantity
    FROM refunded
    UNION ALL
    SELECT role, hd_income_band_sk, hd_buy_potential, cr_return_amount, cr_net_loss, cr_return_quantity
    FROM returning
) AS combined
GROUP BY role, hd_income_band_sk, hd_buy_potential
ORDER BY role, hd_income_band_sk, hd_buy_potential
