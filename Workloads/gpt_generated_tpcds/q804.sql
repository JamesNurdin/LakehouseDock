WITH store_ret AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
web_ret AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
catalog_ret AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    COALESCE(s.ib_income_band_sk, w.ib_income_band_sk, ca.ib_income_band_sk) AS income_band_sk,
    COALESCE(s.ib_lower_bound, w.ib_lower_bound, ca.ib_lower_bound)       AS lower_bound,
    COALESCE(s.ib_upper_bound, w.ib_upper_bound, ca.ib_upper_bound)       AS upper_bound,
    COALESCE(s.store_net_loss, 0)   AS store_net_loss,
    COALESCE(w.web_net_loss, 0)     AS web_net_loss,
    COALESCE(ca.catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(s.store_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) + COALESCE(ca.catalog_return_cnt, 0) AS total_return_cnt,
    COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0) + COALESCE(ca.catalog_net_loss, 0) AS total_net_loss
FROM store_ret s
FULL OUTER JOIN web_ret w   ON s.ib_income_band_sk = w.ib_income_band_sk
FULL OUTER JOIN catalog_ret ca ON COALESCE(s.ib_income_band_sk, w.ib_income_band_sk) = ca.ib_income_band_sk
ORDER BY total_net_loss DESC
LIMIT 10
