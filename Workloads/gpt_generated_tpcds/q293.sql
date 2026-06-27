WITH combined AS (
    -- Store sales (positive net profit)
    SELECT
        ss.ss_promo_sk AS promo_sk,
        d.d_year AS sales_year,
        hd.hd_income_band_sk,
        ss.ss_net_profit AS sales_net_profit,
        CAST(0.0 AS decimal(7,2)) AS return_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk

    UNION ALL

    -- Store returns (negative net loss)
    SELECT
        ss.ss_promo_sk AS promo_sk,
        d.d_year AS sales_year,
        hd.hd_income_band_sk,
        CAST(0.0 AS decimal(7,2)) AS sales_net_profit,
        sr.sr_net_loss AS return_net_loss
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk

    UNION ALL

    -- Web sales (positive net profit)
    SELECT
        ws.ws_promo_sk AS promo_sk,
        d.d_year AS sales_year,
        hd.hd_income_band_sk,
        ws.ws_net_profit AS sales_net_profit,
        CAST(0.0 AS decimal(7,2)) AS return_net_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk

    UNION ALL

    -- Web returns (negative net loss)
    SELECT
        ws.ws_promo_sk AS promo_sk,
        d.d_year AS sales_year,
        hd.hd_income_band_sk,
        CAST(0.0 AS decimal(7,2)) AS sales_net_profit,
        wr.wr_net_loss AS return_net_loss
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk

    UNION ALL

    -- Catalog sales (positive net profit)
    SELECT
        cs.cs_promo_sk AS promo_sk,
        d.d_year AS sales_year,
        hd.hd_income_band_sk,
        cs.cs_net_profit AS sales_net_profit,
        CAST(0.0 AS decimal(7,2)) AS return_net_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk

    UNION ALL

    -- Catalog returns (negative net loss)
    SELECT
        cs.cs_promo_sk AS promo_sk,
        d.d_year AS sales_year,
        hd.hd_income_band_sk,
        CAST(0.0 AS decimal(7,2)) AS sales_net_profit,
        cr.cr_net_loss AS return_net_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
)
SELECT
    p.p_promo_id,
    ib.ib_income_band_sk,
    combined.sales_year,
    SUM(combined.sales_net_profit) AS total_sales_net_profit,
    SUM(combined.return_net_loss) AS total_return_net_loss,
    SUM(combined.sales_net_profit) - SUM(combined.return_net_loss) AS net_profit_after_returns
FROM combined
JOIN promotion p ON combined.promo_sk = p.p_promo_sk
JOIN income_band ib ON combined.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    p.p_promo_id,
    ib.ib_income_band_sk,
    combined.sales_year
ORDER BY
    combined.sales_year,
    p.p_promo_id,
    ib.ib_income_band_sk
