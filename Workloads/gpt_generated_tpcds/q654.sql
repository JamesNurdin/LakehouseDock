WITH ss_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS store_sales_profit
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
cs_agg AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(cs.cs_net_profit) AS catalog_sales_profit
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
ws_agg AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(ws.ws_net_profit) AS web_sales_profit
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
sr_agg AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(sr.sr_net_loss) AS store_returns_loss
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
cr_agg AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(cr.cr_net_loss) AS catalog_returns_loss
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(ss.store_sales_profit, 0)      AS store_sales_profit,
    COALESCE(cs.catalog_sales_profit, 0)    AS catalog_sales_profit,
    COALESCE(ws.web_sales_profit, 0)        AS web_sales_profit,
    COALESCE(sr.store_returns_loss, 0)      AS store_returns_loss,
    COALESCE(cr.catalog_returns_loss, 0)    AS catalog_returns_loss,
    (COALESCE(ss.store_sales_profit, 0) + COALESCE(cs.catalog_sales_profit, 0) + COALESCE(ws.web_sales_profit, 0))
      - (COALESCE(sr.store_returns_loss, 0) + COALESCE(cr.catalog_returns_loss, 0)) AS net_contribution
FROM income_band ib
LEFT JOIN ss_agg ss ON ib.ib_income_band_sk = ss.ib_income_band_sk
LEFT JOIN cs_agg cs ON ib.ib_income_band_sk = cs.ib_income_band_sk
LEFT JOIN ws_agg ws ON ib.ib_income_band_sk = ws.ib_income_band_sk
LEFT JOIN sr_agg sr ON ib.ib_income_band_sk = sr.ib_income_band_sk
LEFT JOIN cr_agg cr ON ib.ib_income_band_sk = cr.ib_income_band_sk
ORDER BY ib.ib_income_band_sk
