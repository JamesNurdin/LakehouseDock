/*
  Analytical query: For each item, compute store net profit, total return net loss,
  current inventory, net quantity sold, and net profit per unit.
*/
WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        SUM(ss.ss_net_profit) AS total_store_net_profit,
        SUM(ss.ss_quantity) AS total_store_quantity_sold
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price
),
all_returns AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS qty_returned
    FROM catalog_returns cr
    UNION ALL
    SELECT
        wr.wr_item_sk AS item_sk,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS qty_returned
    FROM web_returns wr
),
item_returns AS (
    SELECT
        i.i_item_sk,
        SUM(ar.net_loss) AS total_return_net_loss,
        SUM(ar.qty_returned) AS total_quantity_returned
    FROM all_returns ar
    JOIN item i
        ON ar.item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
),
item_inventory AS (
    SELECT
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    COALESCE(s.total_store_net_profit, 0) AS store_net_profit,
    COALESCE(r.total_return_net_loss, 0) AS total_return_net_loss,
    COALESCE(inv.total_quantity_on_hand, 0) AS quantity_on_hand,
    COALESCE(s.total_store_quantity_sold, 0) - COALESCE(r.total_quantity_returned, 0) AS net_quantity_sold,
    (COALESCE(s.total_store_net_profit, 0) - COALESCE(r.total_return_net_loss, 0)) / NULLIF(
        COALESCE(s.total_store_quantity_sold, 0) - COALESCE(r.total_quantity_returned, 0), 0
    ) AS net_profit_per_unit
FROM item i
LEFT JOIN item_sales s
    ON i.i_item_sk = s.i_item_sk
LEFT JOIN item_returns r
    ON i.i_item_sk = r.i_item_sk
LEFT JOIN item_inventory inv
    ON i.i_item_sk = inv.i_item_sk
WHERE COALESCE(s.total_store_quantity_sold, 0) > 0
ORDER BY net_profit_per_unit DESC
LIMIT 100
