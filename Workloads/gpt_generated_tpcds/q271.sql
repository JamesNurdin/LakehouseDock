WITH catalog_ret AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
web_ret AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
store_sales_agg AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
web_sales_agg AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(cr.catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(wr.web_net_loss, 0) AS web_net_loss,
    COALESCE(ss.store_net_profit, 0) AS store_net_profit,
    COALESCE(ws.web_net_profit, 0) AS web_net_profit,
    COALESCE(cr.catalog_return_cnt, 0) AS catalog_return_cnt,
    COALESCE(wr.web_return_cnt, 0) AS web_return_cnt,
    COALESCE(ss.store_sales_cnt, 0) AS store_sales_cnt,
    COALESCE(ws.web_sales_cnt, 0) AS web_sales_cnt,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0)) DESC) AS loss_rank
FROM income_band ib
LEFT JOIN catalog_ret cr
    ON ib.ib_income_band_sk = cr.ib_income_band_sk
LEFT JOIN web_ret wr
    ON ib.ib_income_band_sk = wr.ib_income_band_sk
LEFT JOIN store_sales_agg ss
    ON ib.ib_income_band_sk = ss.ib_income_band_sk
LEFT JOIN web_sales_agg ws
    ON ib.ib_income_band_sk = ws.ib_income_band_sk
ORDER BY ib.ib_income_band_sk
