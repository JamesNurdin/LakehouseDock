WITH
    store_sales_data AS (
        SELECT
            i.i_category AS i_category,
            p.p_promo_name AS p_promo_name,
            ib.ib_lower_bound AS ib_lower_bound,
            ib.ib_upper_bound AS ib_upper_bound,
            ss.ss_net_profit AS profit,
            CAST(0.00 AS decimal(7,2)) AS loss
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),
    store_returns_data AS (
        SELECT
            i.i_category AS i_category,
            p.p_promo_name AS p_promo_name,
            ib.ib_lower_bound AS ib_lower_bound,
            ib.ib_upper_bound AS ib_upper_bound,
            CAST(0.00 AS decimal(7,2)) AS profit,
            sr.sr_net_loss AS loss
        FROM store_returns sr
        JOIN store_sales ss
            ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),
    catalog_sales_data AS (
        SELECT
            i.i_category AS i_category,
            p.p_promo_name AS p_promo_name,
            ib.ib_lower_bound AS ib_lower_bound,
            ib.ib_upper_bound AS ib_upper_bound,
            cs.cs_net_profit AS profit,
            CAST(0.00 AS decimal(7,2)) AS loss
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),
    catalog_returns_data AS (
        SELECT
            i.i_category AS i_category,
            p.p_promo_name AS p_promo_name,
            ib.ib_lower_bound AS ib_lower_bound,
            ib.ib_upper_bound AS ib_upper_bound,
            CAST(0.00 AS decimal(7,2)) AS profit,
            cr.cr_net_loss AS loss
        FROM catalog_returns cr
        JOIN catalog_sales cs
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),
    web_sales_data AS (
        SELECT
            i.i_category AS i_category,
            p.p_promo_name AS p_promo_name,
            ib.ib_lower_bound AS ib_lower_bound,
            ib.ib_upper_bound AS ib_upper_bound,
            ws.ws_net_profit AS profit,
            CAST(0.00 AS decimal(7,2)) AS loss
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),
    web_returns_data AS (
        SELECT
            i.i_category AS i_category,
            p.p_promo_name AS p_promo_name,
            ib.ib_lower_bound AS ib_lower_bound,
            ib.ib_upper_bound AS ib_upper_bound,
            CAST(0.00 AS decimal(7,2)) AS profit,
            wr.wr_net_loss AS loss
        FROM web_returns wr
        JOIN web_sales ws
            ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),
    combined AS (
        SELECT * FROM store_sales_data
        UNION ALL
        SELECT * FROM store_returns_data
        UNION ALL
        SELECT * FROM catalog_sales_data
        UNION ALL
        SELECT * FROM catalog_returns_data
        UNION ALL
        SELECT * FROM web_sales_data
        UNION ALL
        SELECT * FROM web_returns_data
    )
SELECT
    i_category,
    p_promo_name,
    ib_lower_bound,
    ib_upper_bound,
    SUM(profit) AS total_sales_profit,
    SUM(loss) AS total_returns_loss,
    SUM(profit) - SUM(loss) AS net_profit
FROM combined
GROUP BY i_category, p_promo_name, ib_lower_bound, ib_upper_bound
ORDER BY net_profit DESC
LIMIT 20
