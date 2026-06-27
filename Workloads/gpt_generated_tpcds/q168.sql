WITH catalog_sales_agg AS (
    SELECT
        cs_warehouse_sk,
        SUM(cs_net_paid_inc_tax) AS sum_sales_net_paid_inc_tax,
        SUM(cs_net_profit) AS sum_sales_net_profit
    FROM catalog_sales
    GROUP BY cs_warehouse_sk
),
web_sales_agg AS (
    SELECT
        ws_warehouse_sk,
        SUM(ws_net_paid_inc_tax) AS sum_web_sales_net_paid_inc_tax,
        SUM(ws_net_profit) AS sum_web_sales_net_profit
    FROM web_sales
    GROUP BY ws_warehouse_sk
),
catalog_returns_agg AS (
    SELECT
        cr_warehouse_sk,
        SUM(cr_net_loss) AS sum_returns_net_loss
    FROM catalog_returns
    GROUP BY cr_warehouse_sk
),
inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS sum_inventory_quantity
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    COALESCE(cs.sum_sales_net_paid_inc_tax, 0) AS total_sales_net_paid_inc_tax,
    COALESCE(cs.sum_sales_net_profit, 0) AS total_sales_net_profit,
    COALESCE(ws.sum_web_sales_net_paid_inc_tax, 0) AS total_web_sales_net_paid_inc_tax,
    COALESCE(ws.sum_web_sales_net_profit, 0) AS total_web_sales_net_profit,
    COALESCE(r.sum_returns_net_loss, 0) AS total_returns_net_loss,
    COALESCE(i.sum_inventory_quantity, 0) AS total_inventory_quantity,
    COALESCE(cs.sum_sales_net_profit, 0) + COALESCE(ws.sum_web_sales_net_profit, 0) - COALESCE(r.sum_returns_net_loss, 0) AS net_profit_after_returns
FROM warehouse w
LEFT JOIN catalog_sales_agg cs ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_sales_agg ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns_agg r ON r.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_agg i ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_state = 'CA'
ORDER BY net_profit_after_returns DESC
