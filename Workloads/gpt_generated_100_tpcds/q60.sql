WITH store_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_count,
        AVG(sr.sr_return_quantity) AS store_avg_quantity
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
catalog_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_count,
        AVG(cr.cr_return_quantity) AS catalog_avg_quantity
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    COALESCE(s.ib_income_band_sk, c.ib_income_band_sk) AS income_band_sk,
    COALESCE(s.ib_lower_bound, c.ib_lower_bound) AS lower_bound,
    COALESCE(s.ib_upper_bound, c.ib_upper_bound) AS upper_bound,
    s.store_return_amount,
    s.store_net_loss,
    s.store_return_count,
    s.store_avg_quantity,
    c.catalog_return_amount,
    c.catalog_net_loss,
    c.catalog_return_count,
    c.catalog_avg_quantity,
    (COALESCE(s.store_net_loss, 0) - COALESCE(c.catalog_net_loss, 0)) AS net_loss_difference
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.ib_income_band_sk = c.ib_income_band_sk
ORDER BY lower_bound
