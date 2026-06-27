WITH refunded AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        SUM(wr.wr_net_loss) AS total_net_loss_refunded,
        COUNT(*) AS cnt_refunded
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
),
returning AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        SUM(wr.wr_net_loss) AS total_net_loss_returning,
        COUNT(*) AS cnt_returning
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
)
SELECT
    COALESCE(r.ib_lower_bound, f.ib_lower_bound) AS ib_lower_bound,
    COALESCE(r.ib_upper_bound, f.ib_upper_bound) AS ib_upper_bound,
    COALESCE(r.hd_buy_potential, f.hd_buy_potential) AS hd_buy_potential,
    COALESCE(r.total_net_loss_returning, 0) AS net_loss_returning,
    COALESCE(f.total_net_loss_refunded, 0) AS net_loss_refunded,
    COALESCE(r.cnt_returning, 0) AS cnt_returning,
    COALESCE(f.cnt_refunded, 0) AS cnt_refunded,
    COALESCE(r.total_net_loss_returning, 0) - COALESCE(f.total_net_loss_refunded, 0) AS net_loss_diff
FROM returning r
FULL OUTER JOIN refunded f
    ON r.ib_lower_bound = f.ib_lower_bound
   AND r.ib_upper_bound = f.ib_upper_bound
   AND r.hd_buy_potential = f.hd_buy_potential
ORDER BY net_loss_diff DESC
