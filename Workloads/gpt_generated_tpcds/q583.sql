WITH
    store_sales_agg AS (
        SELECT i.i_item_sk,
               SUM(ss.ss_quantity) AS store_quantity,
               SUM(ss.ss_net_profit) AS store_net_profit
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk
    ),
    catalog_sales_agg AS (
        SELECT i.i_item_sk,
               SUM(cs.cs_quantity) AS catalog_quantity,
               SUM(cs.cs_net_profit) AS catalog_net_profit
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk
    ),
    web_sales_agg AS (
        SELECT i.i_item_sk,
               SUM(ws.ws_quantity) AS web_quantity,
               SUM(ws.ws_net_profit) AS web_net_profit
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk
    ),
    store_returns_agg AS (
        SELECT i.i_item_sk,
               SUM(sr.sr_return_quantity) AS store_return_quantity,
               SUM(sr.sr_return_amt) AS store_return_amount
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk
    ),
    catalog_returns_agg AS (
        SELECT i.i_item_sk,
               SUM(cr.cr_return_quantity) AS catalog_return_quantity,
               SUM(cr.cr_return_amount) AS catalog_return_amount
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk
    ),
    web_returns_agg AS (
        SELECT i.i_item_sk,
               SUM(wr.wr_return_quantity) AS web_return_quantity,
               SUM(wr.wr_return_amt) AS web_return_amount
        FROM web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk
    ),
    inventory_agg AS (
        SELECT i.i_item_sk,
               SUM(inv.inv_quantity_on_hand) AS inventory_quantity_on_hand
        FROM inventory inv
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    COALESCE(ss.store_quantity, 0) + COALESCE(cs.catalog_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_sales_quantity,
    COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_sales_net_profit,
    COALESCE(sr.store_return_quantity, 0) + COALESCE(cr.catalog_return_quantity, 0) + COALESCE(wr.web_return_quantity, 0) AS total_return_quantity,
    COALESCE(sr.store_return_amount, 0) + COALESCE(cr.catalog_return_amount, 0) + COALESCE(wr.web_return_amount, 0) AS total_return_amount,
    COALESCE(inv.inventory_quantity_on_hand, 0) AS inventory_on_hand,
    (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0))
        - (COALESCE(sr.store_return_amount, 0) + COALESCE(cr.catalog_return_amount, 0) + COALESCE(wr.web_return_amount, 0))
        AS net_profit_after_returns
FROM item i
LEFT JOIN store_sales_agg ss   ON ss.i_item_sk = i.i_item_sk
LEFT JOIN catalog_sales_agg cs ON cs.i_item_sk = i.i_item_sk
LEFT JOIN web_sales_agg ws     ON ws.i_item_sk = i.i_item_sk
LEFT JOIN store_returns_agg sr ON sr.i_item_sk = i.i_item_sk
LEFT JOIN catalog_returns_agg cr ON cr.i_item_sk = i.i_item_sk
LEFT JOIN web_returns_agg wr   ON wr.i_item_sk = i.i_item_sk
LEFT JOIN inventory_agg inv    ON inv.i_item_sk = i.i_item_sk
ORDER BY net_profit_after_returns DESC
LIMIT 20
