WITH store_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
catalog_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    COALESCE(s.ib_income_band_sk, c.ib_income_band_sk) AS income_band_sk,
    COALESCE(s.ib_lower_bound, c.ib_lower_bound) AS lower_bound,
    COALESCE(s.ib_upper_bound, c.ib_upper_bound) AS upper_bound,
    s.store_net_loss,
    s.store_return_cnt,
    c.catalog_net_loss,
    c.catalog_return_cnt,
    (COALESCE(s.store_net_loss, 0) + COALESCE(c.catalog_net_loss, 0)) AS total_net_loss,
    (COALESCE(s.store_return_cnt, 0) + COALESCE(c.catalog_return_cnt, 0)) AS total_return_cnt
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.ib_income_band_sk = c.ib_income_band_sk
ORDER BY total_net_loss DESC
LIMIT 10
