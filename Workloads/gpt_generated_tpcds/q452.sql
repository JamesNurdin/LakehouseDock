WITH cs_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_catalog_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_warehouse_sk
),
ws_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM web_sales ws
    GROUP BY ws.ws_warehouse_sk
),
cr_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_warehouse_sk
),
inv_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(ws.total_web_sales, 0) AS total_web_sales,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(inv.total_inventory_qty, 0) AS total_inventory_qty,
    (COALESCE(cs.total_catalog_sales, 0) + COALESCE(ws.total_web_sales, 0) - COALESCE(cr.total_return_amount, 0)) AS net_sales_amount,
    (COALESCE(cs.total_catalog_profit, 0) + COALESCE(ws.total_web_profit, 0) - COALESCE(cr.total_return_loss, 0)) AS net_profit
FROM warehouse w
LEFT JOIN cs_agg cs ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ws_agg ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN cr_agg cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inv_agg inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
ORDER BY net_sales_amount DESC
LIMIT 10
