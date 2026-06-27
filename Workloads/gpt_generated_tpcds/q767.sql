WITH
    store_sales_profit AS (
        SELECT
            ib.ib_income_band_sk,
            i.i_category,
            SUM(ss.ss_net_profit) AS profit
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        GROUP BY ib.ib_income_band_sk, i.i_category
    ),
    catalog_sales_profit AS (
        SELECT
            ib.ib_income_band_sk,
            i.i_category,
            SUM(cs.cs_net_profit) AS profit
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        GROUP BY ib.ib_income_band_sk, i.i_category
    ),
    web_sales_profit AS (
        SELECT
            ib.ib_income_band_sk,
            i.i_category,
            SUM(ws.ws_net_profit) AS profit
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        GROUP BY ib.ib_income_band_sk, i.i_category
    ),
    store_returns_loss AS (
        SELECT
            ib.ib_income_band_sk,
            i.i_category,
            SUM(sr.sr_net_loss) AS loss
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        GROUP BY ib.ib_income_band_sk, i.i_category
    ),
    catalog_returns_loss AS (
        SELECT
            ib.ib_income_band_sk,
            i.i_category,
            SUM(cr.cr_net_loss) AS loss
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        GROUP BY ib.ib_income_band_sk, i.i_category
    ),
    web_returns_loss AS (
        SELECT
            ib.ib_income_band_sk,
            i.i_category,
            SUM(wr.wr_net_loss) AS loss
        FROM web_returns wr
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        GROUP BY ib.ib_income_band_sk, i.i_category
    ),
    combined AS (
        SELECT ib_income_band_sk, i_category, profit FROM store_sales_profit
        UNION ALL
        SELECT ib_income_band_sk, i_category, profit FROM catalog_sales_profit
        UNION ALL
        SELECT ib_income_band_sk, i_category, profit FROM web_sales_profit
        UNION ALL
        SELECT ib_income_band_sk, i_category, -loss AS profit FROM store_returns_loss
        UNION ALL
        SELECT ib_income_band_sk, i_category, -loss AS profit FROM catalog_returns_loss
        UNION ALL
        SELECT ib_income_band_sk, i_category, -loss AS profit FROM web_returns_loss
    )
SELECT
    ib_income_band_sk,
    i_category,
    SUM(profit) AS total_net_profit
FROM combined
GROUP BY ib_income_band_sk, i_category
ORDER BY total_net_profit DESC
LIMIT 20
