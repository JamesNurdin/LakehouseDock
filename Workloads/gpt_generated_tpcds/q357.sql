WITH
    store_sales_agg AS (
        SELECT
            ib.ib_income_band_sk AS income_band_sk,
            SUM(ss.ss_net_profit) AS store_net_profit,
            COUNT(DISTINCT ss.ss_customer_sk) AS store_customer_cnt
        FROM store_sales ss
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    ),
    catalog_sales_agg AS (
        SELECT
            ib.ib_income_band_sk AS income_band_sk,
            SUM(cs.cs_net_profit) AS catalog_net_profit,
            COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customer_cnt
        FROM catalog_sales cs
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    ),
    web_sales_agg AS (
        SELECT
            ib.ib_income_band_sk AS income_band_sk,
            SUM(ws.ws_net_profit) AS web_net_profit,
            COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customer_cnt
        FROM web_sales ws
        JOIN household_demographics hd
            ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    ),
    store_returns_agg AS (
        SELECT
            ib.ib_income_band_sk AS income_band_sk,
            SUM(sr.sr_net_loss) AS store_net_loss,
            COUNT(DISTINCT sr.sr_customer_sk) AS store_return_customer_cnt
        FROM store_returns sr
        JOIN household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    ),
    catalog_returns_agg AS (
        SELECT
            ib.ib_income_band_sk AS income_band_sk,
            SUM(cr.cr_net_loss) AS catalog_net_loss,
            COUNT(DISTINCT cr.cr_refunded_customer_sk) AS catalog_return_customer_cnt
        FROM catalog_returns cr
        JOIN household_demographics hd
            ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    ),
    web_returns_agg AS (
        SELECT
            ib.ib_income_band_sk AS income_band_sk,
            SUM(wr.wr_net_loss) AS web_net_loss,
            COUNT(DISTINCT wr.wr_refunded_customer_sk) AS web_return_customer_cnt
        FROM web_returns wr
        JOIN household_demographics hd
            ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    )
SELECT
    ib.ib_income_band_sk AS income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(ss.store_net_profit, 0)      AS store_net_profit,
    COALESCE(cs.catalog_net_profit, 0)    AS catalog_net_profit,
    COALESCE(ws.web_net_profit, 0)        AS web_net_profit,
    COALESCE(sr.store_net_loss, 0)        AS store_net_loss,
    COALESCE(cr.catalog_net_loss, 0)      AS catalog_net_loss,
    COALESCE(wr.web_net_loss, 0)          AS web_net_loss,
    (
        COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
        - COALESCE(sr.store_net_loss, 0) - COALESCE(cr.catalog_net_loss, 0) - COALESCE(wr.web_net_loss, 0)
    )                                      AS net_profit_after_returns,
    (
        COALESCE(ss.store_customer_cnt, 0) + COALESCE(cs.catalog_customer_cnt, 0) + COALESCE(ws.web_customer_cnt, 0)
        + COALESCE(sr.store_return_customer_cnt, 0) + COALESCE(cr.catalog_return_customer_cnt, 0) + COALESCE(wr.web_return_customer_cnt, 0)
    )                                      AS total_customer_interactions
FROM income_band ib
LEFT JOIN store_sales_agg ss   ON ib.ib_income_band_sk = ss.income_band_sk
LEFT JOIN catalog_sales_agg cs ON ib.ib_income_band_sk = cs.income_band_sk
LEFT JOIN web_sales_agg ws    ON ib.ib_income_band_sk = ws.income_band_sk
LEFT JOIN store_returns_agg sr ON ib.ib_income_band_sk = sr.income_band_sk
LEFT JOIN catalog_returns_agg cr ON ib.ib_income_band_sk = cr.income_band_sk
LEFT JOIN web_returns_agg wr   ON ib.ib_income_band_sk = wr.income_band_sk
ORDER BY net_profit_after_returns DESC
