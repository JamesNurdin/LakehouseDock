WITH filtered_returns AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_refunded_hdemo_sk
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE
        hd.hd_buy_potential IN ('5001-10000', '1001-5000')
        AND hd.hd_vehicle_count >= 1
        AND hd.hd_income_band_sk BETWEEN 5 AND 12
        AND cr.cr_net_loss > 100
        AND cr.cr_refunded_hdemo_sk IN (7188, 6145)
),
per_group AS (
    SELECT
        hd_income_band_sk,
        hd_buy_potential,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM filtered_returns
    GROUP BY hd_income_band_sk, hd_buy_potential
)
SELECT
    hd_income_band_sk,
    AVG(total_return_amount) AS avg_return_amount_per_potential,
    SUM(return_cnt) AS total_returns,
    SUM(total_net_loss) AS total_net_loss
FROM per_group
GROUP BY hd_income_band_sk
HAVING SUM(return_cnt) > 10
ORDER BY hd_income_band_sk
