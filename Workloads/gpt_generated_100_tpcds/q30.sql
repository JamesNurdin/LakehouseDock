WITH catalog_metrics AS (
    SELECT
        cs.cs_warehouse_sk,
        sum(cs.cs_net_profit) AS catalog_net_profit,
        sum(cs.cs_net_paid_inc_tax) AS catalog_net_paid_inc_tax,
        sum(cs.cs_ext_sales_price) AS catalog_ext_sales_price,
        sum(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    GROUP BY cs.cs_warehouse_sk
),
web_metrics AS (
    SELECT
        ws.ws_warehouse_sk,
        sum(ws.ws_net_profit) AS web_net_profit,
        sum(ws.ws_net_paid_inc_tax) AS web_net_paid_inc_tax,
        sum(ws.ws_ext_sales_price) AS web_ext_sales_price,
        sum(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_warehouse_sk
),
return_metrics AS (
    SELECT
        cr.cr_warehouse_sk,
        sum(cr.cr_net_loss) AS return_net_loss,
        sum(cr.cr_return_quantity) AS return_quantity,
        sum(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_warehouse_sk
),
inventory_metrics AS (
    SELECT
        inv.inv_warehouse_sk,
        sum(inv.inv_quantity_on_hand) AS inventory_on_hand
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    coalesce(cm.catalog_net_profit, 0) AS catalog_net_profit,
    coalesce(wm.web_net_profit, 0) AS web_net_profit,
    coalesce(rm.return_net_loss, 0) AS return_net_loss,
    coalesce(im.inventory_on_hand, 0) AS inventory_on_hand,
    (coalesce(cm.catalog_net_profit, 0) + coalesce(wm.web_net_profit, 0) - coalesce(rm.return_net_loss, 0)) AS total_net_contribution,
    CASE
        WHEN (coalesce(cm.catalog_quantity, 0) + coalesce(wm.web_quantity, 0)) = 0 THEN 0
        ELSE cast(coalesce(rm.return_quantity, 0) AS double) / nullif((coalesce(cm.catalog_quantity, 0) + coalesce(wm.web_quantity, 0)), 0)
    END AS return_rate
FROM warehouse w
LEFT JOIN catalog_metrics cm ON cm.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_metrics wm ON wm.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN return_metrics rm ON rm.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_metrics im ON im.inv_warehouse_sk = w.w_warehouse_sk
WHERE coalesce(im.inventory_on_hand, 0) > 0
ORDER BY total_net_contribution DESC
