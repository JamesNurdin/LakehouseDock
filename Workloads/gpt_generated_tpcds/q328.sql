WITH
    store_sales_agg AS (
        SELECT
            i.i_item_sk,
            i.i_product_name,
            i.i_brand,
            i.i_category,
            SUM(ss.ss_net_profit) AS store_net_profit,
            SUM(ss.ss_net_paid) AS store_net_paid,
            SUM(ss.ss_quantity) AS store_quantity
        FROM store_sales ss
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk, i.i_product_name, i.i_brand, i.i_category
    ),
    store_returns_agg AS (
        SELECT
            i.i_item_sk,
            SUM(sr.sr_net_loss) AS store_net_loss,
            SUM(sr.sr_return_quantity) AS store_return_quantity
        FROM store_returns sr
        JOIN item i
            ON sr.sr_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk
    ),
    web_sales_agg AS (
        SELECT
            i.i_item_sk,
            i.i_product_name,
            i.i_brand,
            i.i_category,
            SUM(ws.ws_net_profit) AS web_net_profit,
            SUM(ws.ws_net_paid) AS web_net_paid,
            SUM(ws.ws_quantity) AS web_quantity
        FROM web_sales ws
        JOIN item i
            ON ws.ws_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk, i.i_product_name, i.i_brand, i.i_category
    ),
    web_returns_agg AS (
        SELECT
            i.i_item_sk,
            SUM(wr.wr_net_loss) AS web_net_loss,
            SUM(wr.wr_return_quantity) AS web_return_quantity
        FROM web_returns wr
        JOIN item i
            ON wr.wr_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk
    )
SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    (COALESCE(ss.store_net_profit, 0) - COALESCE(sr.store_net_loss, 0))
    + (COALESCE(ws.web_net_profit, 0) - COALESCE(wr.web_net_loss, 0)) AS total_net_profit,
    COALESCE(ss.store_net_profit, 0) - COALESCE(sr.store_net_loss, 0) AS store_net_profit_adj,
    COALESCE(ws.web_net_profit, 0) - COALESCE(wr.web_net_loss, 0) AS web_net_profit_adj
FROM item i
LEFT JOIN store_sales_agg ss
    ON i.i_item_sk = ss.i_item_sk
LEFT JOIN store_returns_agg sr
    ON i.i_item_sk = sr.i_item_sk
LEFT JOIN web_sales_agg ws
    ON i.i_item_sk = ws.i_item_sk
LEFT JOIN web_returns_agg wr
    ON i.i_item_sk = wr.i_item_sk
ORDER BY total_net_profit DESC
LIMIT 100
