-- Goal: Compare total return amounts across catalog, store, and web channels for items in the 'pants' class, 
-- grouped by manager, while ensuring sufficient inventory and filtering on manager IDs.
WITH item_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_class,
        i.i_manager_id,
        COALESCE(SUM(cr.cr_return_amount), 0) AS catalog_return_amount,
        COALESCE(SUM(sr.sr_return_amt), 0) AS store_return_amount,
        COALESCE(SUM(wr.wr_return_amt), 0) AS web_return_amount,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_qty,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_tickets,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders
    FROM item i
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE i.i_class = 'pants'
      AND i.i_manager_id IN (3, 23, 51)
      AND inv.inv_quantity_on_hand > 600
    GROUP BY i.i_item_sk, i.i_item_id, i.i_class, i.i_manager_id
)
SELECT
    ia.i_manager_id,
    ia.i_class,
    SUM(ia.catalog_return_amount + ia.store_return_amount + ia.web_return_amount) AS total_return_amount,
    AVG(ia.total_inventory_qty) AS avg_inventory_qty,
    COUNT(DISTINCT ia.i_item_id) AS distinct_items
FROM item_agg ia
GROUP BY ia.i_manager_id, ia.i_class
HAVING SUM(ia.catalog_return_amount + ia.store_return_amount + ia.web_return_amount) > 10000
ORDER BY total_return_amount DESC
LIMIT 100
