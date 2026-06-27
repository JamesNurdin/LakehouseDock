WITH catalog_sales_agg AS (
    SELECT
        cs.cs_warehouse_sk AS warehouse_sk,
        sum(cs.cs_net_profit) AS total_catalog_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_warehouse_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_warehouse_sk AS warehouse_sk,
        sum(ws.ws_net_profit) AS total_web_profit
    FROM web_sales ws
    GROUP BY ws.ws_warehouse_sk
),
inventory_agg AS (
    SELECT
        inv.inv_warehouse_sk AS warehouse_sk,
        sum(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    coalesce(cs.total_catalog_profit, 0) AS total_catalog_profit,
    coalesce(ws.total_web_profit, 0) AS total_web_profit,
    coalesce(inv.total_inventory_qty, 0) AS total_inventory_qty,
    CASE
        WHEN coalesce(inv.total_inventory_qty, 0) > 0
        THEN (coalesce(cs.total_catalog_profit, 0) + coalesce(ws.total_web_profit, 0)) / coalesce(inv.total_inventory_qty, 0)
        ELSE null
    END AS profit_per_inventory_unit
FROM warehouse w
LEFT JOIN catalog_sales_agg cs ON w.w_warehouse_sk = cs.warehouse_sk
LEFT JOIN web_sales_agg ws ON w.w_warehouse_sk = ws.warehouse_sk
LEFT JOIN inventory_agg inv ON w.w_warehouse_sk = inv.warehouse_sk
ORDER BY (coalesce(cs.total_catalog_profit, 0) + coalesce(ws.total_web_profit, 0)) DESC
LIMIT 100
