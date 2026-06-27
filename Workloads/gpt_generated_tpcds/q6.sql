WITH
    catalog_sales_agg AS (
        SELECT cs_warehouse_sk,
               sum(cs_net_profit)          AS total_sales_profit,
               sum(cs_net_paid)            AS total_sales_paid,
               sum(cs_quantity)            AS total_sales_quantity
        FROM catalog_sales
        GROUP BY cs_warehouse_sk
    ),
    web_sales_agg AS (
        SELECT ws_warehouse_sk,
               sum(ws_net_profit)          AS total_web_profit,
               sum(ws_net_paid)            AS total_web_paid,
               sum(ws_quantity)            AS total_web_quantity
        FROM web_sales
        GROUP BY ws_warehouse_sk
    ),
    returns_agg AS (
        SELECT cr_warehouse_sk,
               sum(cr_net_loss)            AS total_return_loss,
               sum(cr_return_quantity)     AS total_return_quantity
        FROM catalog_returns
        GROUP BY cr_warehouse_sk
    ),
    inventory_agg AS (
        SELECT inv_warehouse_sk,
               avg(inv_quantity_on_hand)   AS avg_inventory_qty,
               sum(inv_quantity_on_hand)   AS total_inventory_qty,
               count(*)                    AS inventory_records
        FROM inventory
        GROUP BY inv_warehouse_sk
    )
SELECT
    w.w_warehouse_name,
    coalesce(cs.total_sales_profit, 0)         AS total_sales_profit,
    coalesce(ws.total_web_profit, 0)           AS total_web_profit,
    coalesce(r.total_return_loss, 0)           AS total_return_loss,
    coalesce(i.avg_inventory_qty, 0)           AS avg_inventory_qty,
    (coalesce(cs.total_sales_profit, 0) + coalesce(ws.total_web_profit, 0) - coalesce(r.total_return_loss, 0)) AS net_profit_after_returns
FROM warehouse w
LEFT JOIN catalog_sales_agg cs ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_sales_agg     ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN returns_agg       r  ON r.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_agg    i  ON i.inv_warehouse_sk = w.w_warehouse_sk
-- Example filter: only warehouses in California (optional)
-- WHERE w.w_state = 'CA'
ORDER BY net_profit_after_returns DESC
