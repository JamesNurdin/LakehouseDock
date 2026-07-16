WITH
    store_sales_agg AS (
        SELECT
            ib.ib_income_band_sk,
            SUM(ss.ss_net_profit)                      AS store_net_profit,
            COUNT(DISTINCT ss.ss_customer_sk)          AS store_customers
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    ),
    store_returns_agg AS (
        SELECT
            ib.ib_income_band_sk,
            SUM(sr.sr_net_loss)                       AS store_net_loss,
            COUNT(DISTINCT sr.sr_customer_sk)         AS store_return_customers
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    ),
    catalog_sales_agg AS (
        SELECT
            ib.ib_income_band_sk,
            SUM(cs.cs_net_profit)                     AS catalog_net_profit,
            COUNT(DISTINCT cs.cs_bill_customer_sk)    AS catalog_customers
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    ),
    catalog_returns_agg AS (
        SELECT
            ib.ib_income_band_sk,
            SUM(cr.cr_net_loss)                       AS catalog_net_loss,
            COUNT(DISTINCT cr.cr_refunded_customer_sk) AS catalog_return_customers
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    ),
    web_sales_agg AS (
        SELECT
            ib.ib_income_band_sk,
            SUM(ws.ws_net_profit)                     AS web_net_profit,
            COUNT(DISTINCT ws.ws_bill_customer_sk)    AS web_customers
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    ),
    web_returns_agg AS (
        SELECT
            ib.ib_income_band_sk,
            SUM(wr.wr_net_loss)                       AS web_net_loss,
            COUNT(DISTINCT wr.wr_refunded_customer_sk) AS web_return_customers
        FROM web_returns wr
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_income_band_sk
    ),
    combined AS (
        SELECT
            ib.ib_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            COALESCE(store_sales_agg.store_net_profit, 0) - COALESCE(store_returns_agg.store_net_loss, 0)      AS net_profit_store,
            COALESCE(catalog_sales_agg.catalog_net_profit, 0) - COALESCE(catalog_returns_agg.catalog_net_loss, 0) AS net_profit_catalog,
            COALESCE(web_sales_agg.web_net_profit, 0) - COALESCE(web_returns_agg.web_net_loss, 0)                AS net_profit_web,
            COALESCE(store_sales_agg.store_net_profit, 0)
                + COALESCE(catalog_sales_agg.catalog_net_profit, 0)
                + COALESCE(web_sales_agg.web_net_profit, 0)
                - COALESCE(store_returns_agg.store_net_loss, 0)
                - COALESCE(catalog_returns_agg.catalog_net_loss, 0)
                - COALESCE(web_returns_agg.web_net_loss, 0)                                                     AS total_net_profit,
            COALESCE(store_sales_agg.store_customers, 0)
                + COALESCE(catalog_sales_agg.catalog_customers, 0)
                + COALESCE(web_sales_agg.web_customers, 0)                                                    AS distinct_customers_estimate,
            COALESCE(store_returns_agg.store_return_customers, 0)
                + COALESCE(catalog_returns_agg.catalog_return_customers, 0)
                + COALESCE(web_returns_agg.web_return_customers, 0)                                          AS distinct_return_customers_estimate
        FROM income_band ib
        LEFT JOIN store_sales_agg   ON ib.ib_income_band_sk = store_sales_agg.ib_income_band_sk
        LEFT JOIN store_returns_agg ON ib.ib_income_band_sk = store_returns_agg.ib_income_band_sk
        LEFT JOIN catalog_sales_agg ON ib.ib_income_band_sk = catalog_sales_agg.ib_income_band_sk
        LEFT JOIN catalog_returns_agg ON ib.ib_income_band_sk = catalog_returns_agg.ib_income_band_sk
        LEFT JOIN web_sales_agg    ON ib.ib_income_band_sk = web_sales_agg.ib_income_band_sk
        LEFT JOIN web_returns_agg  ON ib.ib_income_band_sk = web_returns_agg.ib_income_band_sk
    )
SELECT
    combined.ib_income_band_sk,
    combined.ib_lower_bound,
    combined.ib_upper_bound,
    combined.net_profit_store,
    combined.net_profit_catalog,
    combined.net_profit_web,
    combined.total_net_profit,
    combined.distinct_customers_estimate,
    combined.distinct_return_customers_estimate,
    RANK() OVER (ORDER BY combined.total_net_profit DESC) AS profit_rank
FROM combined
ORDER BY profit_rank
