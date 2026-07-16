WITH sales_and_returns AS (
    -- Store sales (profit only)
    SELECT
        d.d_year AS year,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        ss.ss_net_profit AS profit,
        CAST(0 AS decimal(7,2)) AS loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Catalog sales (profit only)
    SELECT
        d.d_year,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_net_profit,
        CAST(0 AS decimal(7,2))
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Web sales (profit only)
    SELECT
        d.d_year,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_net_profit,
        CAST(0 AS decimal(7,2))
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Store returns (loss only)
    SELECT
        d.d_year,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CAST(0 AS decimal(7,2)),
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Catalog returns (loss only)
    SELECT
        d.d_year,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CAST(0 AS decimal(7,2)),
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Web returns (loss only)
    SELECT
        d.d_year,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CAST(0 AS decimal(7,2)),
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    year,
    income_lower,
    income_upper,
    SUM(profit) AS total_profit,
    SUM(loss)   AS total_loss,
    SUM(profit) - SUM(loss) AS net_profit
FROM sales_and_returns
WHERE year BETWEEN 1999 AND 2001
GROUP BY year, income_lower, income_upper
ORDER BY year, income_lower
