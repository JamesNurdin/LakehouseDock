WITH cust_income AS (
    SELECT
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        customer c
        JOIN household_demographics hd
            ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
store_sales_agg AS (
    SELECT
        ci.ib_income_band_sk,
        ci.c_preferred_cust_flag,
        SUM(ss.ss_net_profit) AS store_sales_profit
    FROM
        store_sales ss
        JOIN cust_income ci
            ON ss.ss_customer_sk = ci.c_customer_sk
    GROUP BY
        ci.ib_income_band_sk,
        ci.c_preferred_cust_flag
),
catalog_sales_agg AS (
    SELECT
        ci.ib_income_band_sk,
        ci.c_preferred_cust_flag,
        SUM(cs.cs_net_profit) AS catalog_sales_profit
    FROM
        catalog_sales cs
        JOIN cust_income ci
            ON cs.cs_bill_customer_sk = ci.c_customer_sk
    GROUP BY
        ci.ib_income_band_sk,
        ci.c_preferred_cust_flag
),
web_sales_agg AS (
    SELECT
        ci.ib_income_band_sk,
        ci.c_preferred_cust_flag,
        SUM(ws.ws_net_profit) AS web_sales_profit
    FROM
        web_sales ws
        JOIN cust_income ci
            ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY
        ci.ib_income_band_sk,
        ci.c_preferred_cust_flag
),
store_returns_agg AS (
    SELECT
        ci.ib_income_band_sk,
        ci.c_preferred_cust_flag,
        SUM(sr.sr_net_loss) AS store_returns_loss
    FROM
        store_returns sr
        JOIN cust_income ci
            ON sr.sr_customer_sk = ci.c_customer_sk
    GROUP BY
        ci.ib_income_band_sk,
        ci.c_preferred_cust_flag
),
web_returns_agg AS (
    SELECT
        ci.ib_income_band_sk,
        ci.c_preferred_cust_flag,
        SUM(wr.wr_net_loss) AS web_returns_loss
    FROM
        web_returns wr
        JOIN cust_income ci
            ON wr.wr_refunded_customer_sk = ci.c_customer_sk
    GROUP BY
        ci.ib_income_band_sk,
        ci.c_preferred_cust_flag
)
SELECT
    COALESCE(ss.ib_income_band_sk, cs.ib_income_band_sk, ws.ib_income_band_sk, sr.ib_income_band_sk, wr.ib_income_band_sk) AS income_band_sk,
    COALESCE(ss.c_preferred_cust_flag, cs.c_preferred_cust_flag, ws.c_preferred_cust_flag, sr.c_preferred_cust_flag, wr.c_preferred_cust_flag) AS preferred_cust_flag,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.store_sales_profit,
    cs.catalog_sales_profit,
    ws.web_sales_profit,
    sr.store_returns_loss,
    wr.web_returns_loss,
    (COALESCE(ss.store_sales_profit, 0) + COALESCE(cs.catalog_sales_profit, 0) + COALESCE(ws.web_sales_profit, 0)
     - COALESCE(sr.store_returns_loss, 0) - COALESCE(wr.web_returns_loss, 0)) AS net_profit_after_returns
FROM
    store_sales_agg ss
    FULL OUTER JOIN catalog_sales_agg cs
        ON ss.ib_income_band_sk = cs.ib_income_band_sk
        AND ss.c_preferred_cust_flag = cs.c_preferred_cust_flag
    FULL OUTER JOIN web_sales_agg ws
        ON COALESCE(ss.ib_income_band_sk, cs.ib_income_band_sk) = ws.ib_income_band_sk
        AND COALESCE(ss.c_preferred_cust_flag, cs.c_preferred_cust_flag) = ws.c_preferred_cust_flag
    FULL OUTER JOIN store_returns_agg sr
        ON COALESCE(ss.ib_income_band_sk, cs.ib_income_band_sk, ws.ib_income_band_sk) = sr.ib_income_band_sk
        AND COALESCE(ss.c_preferred_cust_flag, cs.c_preferred_cust_flag, ws.c_preferred_cust_flag) = sr.c_preferred_cust_flag
    FULL OUTER JOIN web_returns_agg wr
        ON COALESCE(ss.ib_income_band_sk, cs.ib_income_band_sk, ws.ib_income_band_sk, sr.ib_income_band_sk) = wr.ib_income_band_sk
        AND COALESCE(ss.c_preferred_cust_flag, cs.c_preferred_cust_flag, ws.c_preferred_cust_flag, sr.c_preferred_cust_flag) = wr.c_preferred_cust_flag
    LEFT JOIN income_band ib
        ON COALESCE(ss.ib_income_band_sk, cs.ib_income_band_sk, ws.ib_income_band_sk, sr.ib_income_band_sk, wr.ib_income_band_sk) = ib.ib_income_band_sk
ORDER BY
    income_band_sk,
    preferred_cust_flag
