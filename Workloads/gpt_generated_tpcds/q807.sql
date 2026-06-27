WITH catalog_sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_state,
        w.w_warehouse_name,
        sum(cs.cs_net_profit) AS catalog_sales_net_profit
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_state, w.w_warehouse_name
),
web_sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        sum(ws.ws_net_profit) AS web_sales_net_profit
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
catalog_returns_agg AS (
    SELECT
        w.w_warehouse_sk,
        sum(cr.cr_net_loss) AS catalog_returns_net_loss
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
inventory_agg AS (
    SELECT
        w.w_warehouse_sk,
        sum(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory inv
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT
    w.w_warehouse_sk,
    w.w_warehouse_name,
    w.w_state,
    coalesce(cs_agg.catalog_sales_net_profit, 0) AS catalog_sales_net_profit,
    coalesce(ws_agg.web_sales_net_profit, 0) AS web_sales_net_profit,
    coalesce(cr_agg.catalog_returns_net_loss, 0) AS catalog_returns_net_loss,
    coalesce(inv_agg.total_inventory_on_hand, 0) AS total_inventory_on_hand,
    (coalesce(cs_agg.catalog_sales_net_profit, 0) + coalesce(ws_agg.web_sales_net_profit, 0) - coalesce(cr_agg.catalog_returns_net_loss, 0)) AS net_profit_before_inventory
FROM warehouse w
LEFT JOIN catalog_sales_agg cs_agg
    ON w.w_warehouse_sk = cs_agg.w_warehouse_sk
LEFT JOIN web_sales_agg ws_agg
    ON w.w_warehouse_sk = ws_agg.w_warehouse_sk
LEFT JOIN catalog_returns_agg cr_agg
    ON w.w_warehouse_sk = cr_agg.w_warehouse_sk
LEFT JOIN inventory_agg inv_agg
    ON w.w_warehouse_sk = inv_agg.w_warehouse_sk
ORDER BY net_profit_before_inventory DESC
LIMIT 10
