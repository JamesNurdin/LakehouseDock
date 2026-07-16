WITH store_sales_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_net_paid) AS store_net_paid,
        SUM(ss_net_profit) AS store_net_profit,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_sk
),
store_returns_agg AS (
    SELECT
        sr_item_sk,
        SUM(sr_net_loss) AS store_net_loss,
        SUM(sr_return_quantity) AS store_return_quantity
    FROM store_returns
    GROUP BY sr_item_sk
),
catalog_sales_agg AS (
    SELECT
        cs_item_sk,
        SUM(cs_net_paid) AS catalog_net_paid,
        SUM(cs_net_profit) AS catalog_net_profit,
        SUM(cs_quantity) AS catalog_quantity
    FROM catalog_sales
    GROUP BY cs_item_sk
),
catalog_returns_agg AS (
    SELECT
        cr_item_sk,
        SUM(cr_net_loss) AS catalog_net_loss,
        SUM(cr_return_quantity) AS catalog_return_quantity
    FROM catalog_returns
    GROUP BY cr_item_sk
),
web_sales_agg AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_paid) AS web_net_paid,
        SUM(ws_net_profit) AS web_net_profit,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_sk
),
web_returns_agg AS (
    SELECT
        wr_item_sk,
        SUM(wr_net_loss) AS web_net_loss,
        SUM(wr_return_quantity) AS web_return_quantity
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    COALESCE(ss.store_quantity, 0) + COALESCE(cs.catalog_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity_sold,
    COALESCE(ss.store_net_paid, 0) + COALESCE(cs.catalog_net_paid, 0) + COALESCE(ws.web_net_paid, 0) AS total_net_paid,
    COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_net_profit,
    COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0) AS total_net_loss,
    (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0))
        - (COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0)) AS net_profit_after_returns
FROM item i
LEFT JOIN store_sales_agg ss ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN store_returns_agg sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN catalog_sales_agg cs ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN catalog_returns_agg cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN web_sales_agg ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_returns_agg wr ON wr.wr_item_sk = i.i_item_sk
WHERE (COALESCE(ss.store_quantity, 0) + COALESCE(cs.catalog_quantity, 0) + COALESCE(ws.web_quantity, 0)) > 0
ORDER BY total_net_profit DESC
LIMIT 100
