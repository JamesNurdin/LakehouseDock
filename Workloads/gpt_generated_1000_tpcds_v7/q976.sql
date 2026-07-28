WITH catalog_agg AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        'catalog' AS source,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ib.ib_upper_bound >= 100000
      AND sm.sm_type = 'AIR'
      AND hd.hd_buy_potential = '1001-5000'
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
web_agg AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        'web' AS source,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 100000
      AND hd.hd_buy_potential = '1001-5000'
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY ib_lower_bound, source
