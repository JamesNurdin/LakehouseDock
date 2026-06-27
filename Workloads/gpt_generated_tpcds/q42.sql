WITH
    catalog_sales_agg AS (
        SELECT cs.cs_item_sk AS item_sk,
               SUM(cs.cs_quantity) AS cat_quantity,
               SUM(cs.cs_net_profit) AS cat_net_profit
        FROM catalog_sales cs
        GROUP BY cs.cs_item_sk
    ),
    store_sales_agg AS (
        SELECT ss.ss_item_sk AS item_sk,
               SUM(ss.ss_quantity) AS store_quantity,
               SUM(ss.ss_net_profit) AS store_net_profit
        FROM store_sales ss
        GROUP BY ss.ss_item_sk
    ),
    web_sales_agg AS (
        SELECT ws.ws_item_sk AS item_sk,
               SUM(ws.ws_quantity) AS web_quantity,
               SUM(ws.ws_net_profit) AS web_net_profit
        FROM web_sales ws
        GROUP BY ws.ws_item_sk
    ),
    catalog_returns_agg AS (
        SELECT cr.cr_item_sk AS item_sk,
               SUM(cr.cr_return_quantity) AS cat_return_quantity,
               SUM(cr.cr_net_loss) AS cat_return_loss
        FROM catalog_returns cr
        GROUP BY cr.cr_item_sk
    ),
    store_returns_agg AS (
        SELECT sr.sr_item_sk AS item_sk,
               SUM(sr.sr_return_quantity) AS store_return_quantity,
               SUM(sr.sr_net_loss) AS store_return_loss
        FROM store_returns sr
        GROUP BY sr.sr_item_sk
    ),
    web_returns_agg AS (
        SELECT wr.wr_item_sk AS item_sk,
               SUM(wr.wr_return_quantity) AS web_return_quantity,
               SUM(wr.wr_net_loss) AS web_return_loss
        FROM web_returns wr
        GROUP BY wr.wr_item_sk
    ),
    inventory_agg AS (
        SELECT inv.inv_item_sk AS item_sk,
               SUM(inv.inv_quantity_on_hand) AS inventory_on_hand
        FROM inventory inv
        GROUP BY inv.inv_item_sk
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    COALESCE(cs.cat_quantity, 0) + COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_sold_quantity,
    COALESCE(cr.cat_return_quantity, 0) + COALESCE(sr.store_return_quantity, 0) + COALESCE(wr.web_return_quantity, 0) AS total_return_quantity,
    CASE
        WHEN (COALESCE(cs.cat_quantity, 0) + COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) > 0
        THEN (COALESCE(cr.cat_return_quantity, 0) + COALESCE(sr.store_return_quantity, 0) + COALESCE(wr.web_return_quantity, 0)) /
             (COALESCE(cs.cat_quantity, 0) + COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0))
        ELSE 0
    END AS return_rate,
    COALESCE(cs.cat_net_profit, 0) + COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_sales_net_profit,
    COALESCE(cr.cat_return_loss, 0) + COALESCE(sr.store_return_loss, 0) + COALESCE(wr.web_return_loss, 0) AS total_returns_net_loss,
    (COALESCE(cs.cat_net_profit, 0) + COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0)) -
    (COALESCE(cr.cat_return_loss, 0) + COALESCE(sr.store_return_loss, 0) + COALESCE(wr.web_return_loss, 0)) AS net_gain,
    COALESCE(inv.inventory_on_hand, 0) AS current_inventory_on_hand
FROM item i
LEFT JOIN catalog_sales_agg cs   ON i.i_item_sk = cs.item_sk
LEFT JOIN store_sales_agg ss     ON i.i_item_sk = ss.item_sk
LEFT JOIN web_sales_agg ws       ON i.i_item_sk = ws.item_sk
LEFT JOIN catalog_returns_agg cr ON i.i_item_sk = cr.item_sk
LEFT JOIN store_returns_agg sr   ON i.i_item_sk = sr.item_sk
LEFT JOIN web_returns_agg wr     ON i.i_item_sk = wr.item_sk
LEFT JOIN inventory_agg inv      ON i.i_item_sk = inv.item_sk
ORDER BY net_gain DESC
LIMIT 100
