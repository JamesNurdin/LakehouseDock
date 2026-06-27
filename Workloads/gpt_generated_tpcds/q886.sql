/*
  Net profit and return analysis by product category and household income band
  across store, catalog, and web channels.
*/
WITH store_sales_agg AS (
    SELECT
        i.i_category AS category,
        ib.ib_income_band_sk AS income_band_id,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_category, ib.ib_income_band_sk
),
store_returns_agg AS (
    SELECT
        i.i_category AS category,
        ib.ib_income_band_sk AS income_band_id,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_category, ib.ib_income_band_sk
),
catalog_sales_agg AS (
    SELECT
        i.i_category AS category,
        ib.ib_income_band_sk AS income_band_id,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_category, ib.ib_income_band_sk
),
catalog_returns_agg AS (
    SELECT
        i.i_category AS category,
        ib.ib_income_band_sk AS income_band_id,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_qty
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_category, ib.ib_income_band_sk
),
web_sales_agg AS (
    SELECT
        i.i_category AS category,
        ib.ib_income_band_sk AS income_band_id,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_category, ib.ib_income_band_sk
),
web_returns_agg AS (
    SELECT
        i.i_category AS category,
        ib.ib_income_band_sk AS income_band_id,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_qty
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY i.i_category, ib.ib_income_band_sk
)
SELECT
    COALESCE(ss.category, sr.category, cs.category, cr.category, ws.category, wr.category) AS category,
    COALESCE(ss.income_band_id, sr.income_band_id, cs.income_band_id, cr.income_band_id, ws.income_band_id, wr.income_band_id) AS income_band_id,
    COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_net_profit,
    COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0) AS total_net_loss,
    (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0))
    - (COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0)) AS net_profit_after_returns,
    COALESCE(ss.store_quantity, 0) + COALESCE(cs.catalog_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity_sold,
    COALESCE(sr.store_return_qty, 0) + COALESCE(cr.catalog_return_qty, 0) + COALESCE(wr.web_return_qty, 0) AS total_quantity_returned,
    (COALESCE(sr.store_return_qty, 0) + COALESCE(cr.catalog_return_qty, 0) + COALESCE(wr.web_return_qty, 0)) * 1.0 /
    NULLIF(COALESCE(ss.store_quantity, 0) + COALESCE(cs.catalog_quantity, 0) + COALESCE(ws.web_quantity, 0), 0) AS return_rate
FROM store_sales_agg ss
FULL OUTER JOIN store_returns_agg sr
    ON ss.category = sr.category AND ss.income_band_id = sr.income_band_id
FULL OUTER JOIN catalog_sales_agg cs
    ON COALESCE(ss.category, sr.category) = cs.category
       AND COALESCE(ss.income_band_id, sr.income_band_id) = cs.income_band_id
FULL OUTER JOIN catalog_returns_agg cr
    ON COALESCE(ss.category, sr.category, cs.category) = cr.category
       AND COALESCE(ss.income_band_id, sr.income_band_id, cs.income_band_id) = cr.income_band_id
FULL OUTER JOIN web_sales_agg ws
    ON COALESCE(ss.category, sr.category, cs.category, cr.category) = ws.category
       AND COALESCE(ss.income_band_id, sr.income_band_id, cs.income_band_id, cr.income_band_id) = ws.income_band_id
FULL OUTER JOIN web_returns_agg wr
    ON COALESCE(ss.category, sr.category, cs.category, cr.category, ws.category) = wr.category
       AND COALESCE(ss.income_band_id, sr.income_band_id, cs.income_band_id, cr.income_band_id, ws.income_band_id) = wr.income_band_id
ORDER BY total_net_profit DESC
LIMIT 50
