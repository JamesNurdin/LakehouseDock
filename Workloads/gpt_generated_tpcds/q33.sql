WITH sales_and_returns AS (
    -- Store sales (profit only)
    SELECT
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_net_profit AS profit,
        CAST(0 AS decimal(7,2)) AS loss
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Store returns (loss only)
    SELECT
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CAST(0 AS decimal(7,2)) AS profit,
        sr.sr_net_loss AS loss
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Catalog sales (profit only)
    SELECT
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_net_profit AS profit,
        CAST(0 AS decimal(7,2)) AS loss
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Catalog returns (loss only)
    SELECT
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CAST(0 AS decimal(7,2)) AS profit,
        cr.cr_net_loss AS loss
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Web sales (profit only)
    SELECT
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_net_profit AS profit,
        CAST(0 AS decimal(7,2)) AS loss
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Web returns (loss only)
    SELECT
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CAST(0 AS decimal(7,2)) AS profit,
        wr.wr_net_loss AS loss
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    i_category,
    ib_lower_bound,
    ib_upper_bound,
    SUM(profit) - SUM(loss) AS net_profit,
    SUM(profit) AS total_sales_profit,
    SUM(loss) AS total_return_loss,
    COUNT(*) AS contributing_rows
FROM sales_and_returns
GROUP BY i_category, ib_lower_bound, ib_upper_bound
ORDER BY net_profit DESC
LIMIT 20
