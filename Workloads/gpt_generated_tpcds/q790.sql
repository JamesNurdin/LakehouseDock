WITH refunded AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        SUM(cr.cr_net_loss) AS total_refunded_net_loss,
        SUM(cr.cr_return_amount) AS total_refunded_return_amount,
        SUM(cr.cr_fee) AS total_refunded_fee,
        AVG(cr.cr_return_quantity) AS avg_refunded_return_quantity,
        COUNT(*) AS refunded_return_cnt
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_buy_potential
),
returning AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        SUM(cr.cr_net_loss) AS total_returning_net_loss,
        SUM(cr.cr_return_amount) AS total_returning_return_amount,
        SUM(cr.cr_fee) AS total_returning_fee,
        AVG(cr.cr_return_quantity) AS avg_returning_return_quantity,
        COUNT(*) AS returning_return_cnt
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_buy_potential
)
SELECT
    COALESCE(r.hd_demo_sk, f.hd_demo_sk) AS hd_demo_sk,
    COALESCE(r.hd_income_band_sk, f.hd_income_band_sk) AS hd_income_band_sk,
    COALESCE(r.hd_buy_potential, f.hd_buy_potential) AS hd_buy_potential,
    f.total_refunded_net_loss,
    f.total_refunded_return_amount,
    f.total_refunded_fee,
    f.avg_refunded_return_quantity,
    f.refunded_return_cnt,
    r.total_returning_net_loss,
    r.total_returning_return_amount,
    r.total_returning_fee,
    r.avg_returning_return_quantity,
    r.returning_return_cnt,
    (f.total_refunded_net_loss - r.total_returning_net_loss) AS net_loss_diff
FROM refunded f
FULL OUTER JOIN returning r
    ON f.hd_demo_sk = r.hd_demo_sk
ORDER BY net_loss_diff DESC
LIMIT 20
