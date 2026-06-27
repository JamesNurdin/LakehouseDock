WITH all_data AS (
    -- Sales from the catalog channel
    SELECT
        hd.hd_income_band_sk AS income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_net_profit AS net_profit,
        CAST(0 AS decimal(7,2)) AS net_loss
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Sales from the web channel
    SELECT
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_net_profit,
        CAST(0 AS decimal(7,2))
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Sales from the store channel
    SELECT
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_net_profit,
        CAST(0 AS decimal(7,2))
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Returns from the catalog channel
    SELECT
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CAST(0 AS decimal(7,2)),
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Returns from the web channel
    SELECT
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CAST(0 AS decimal(7,2)),
        wr.wr_net_loss
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    SUM(net_profit) AS total_net_profit,
    SUM(net_loss) AS total_net_loss,
    SUM(net_profit) - SUM(net_loss) AS net_profit_after_returns
FROM all_data
GROUP BY ib_lower_bound, ib_upper_bound
ORDER BY ib_lower_bound
