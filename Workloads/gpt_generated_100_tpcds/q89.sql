WITH combined AS (
    -- Store sales (profit only)
    SELECT
        i.i_item_id,
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS net_profit,
        0 AS net_loss
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_item_id, i.i_category, ib.ib_lower_bound, ib.ib_upper_bound

    UNION ALL

    -- Store returns (loss only)
    SELECT
        i.i_item_id,
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        0 AS net_profit,
        SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_item_id, i.i_category, ib.ib_lower_bound, ib.ib_upper_bound

    UNION ALL

    -- Catalog sales (profit only)
    SELECT
        i.i_item_id,
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS net_profit,
        0 AS net_loss
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_item_id, i.i_category, ib.ib_lower_bound, ib.ib_upper_bound

    UNION ALL

    -- Catalog returns (loss only)
    SELECT
        i.i_item_id,
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        0 AS net_profit,
        SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_item_id, i.i_category, ib.ib_lower_bound, ib.ib_upper_bound

    UNION ALL

    -- Web sales (profit only)
    SELECT
        i.i_item_id,
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_net_profit) AS net_profit,
        0 AS net_loss
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_item_id, i.i_category, ib.ib_lower_bound, ib.ib_upper_bound

    UNION ALL

    -- Web returns (loss only)
    SELECT
        i.i_item_id,
        i.i_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        0 AS net_profit,
        SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_item_id, i.i_category, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    i_item_id,
    i_category,
    ib_lower_bound,
    ib_upper_bound,
    SUM(net_profit) AS total_net_profit,
    SUM(net_loss)   AS total_net_loss,
    SUM(net_profit) - SUM(net_loss) AS net_profit_after_returns
FROM combined
GROUP BY i_item_id, i_category, ib_lower_bound, ib_upper_bound
ORDER BY net_profit_after_returns DESC
LIMIT 100
