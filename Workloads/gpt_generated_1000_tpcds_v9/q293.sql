WITH base AS (
    SELECT
        sm_cr.sm_type AS return_ship_type,
        w_wh.w_state AS return_warehouse_state,
        ws_site.web_mkt_desc AS market_description,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_sales_orders,
        (SELECT COUNT(*) FROM inventory) AS total_inventory_records,
        MAX(CASE WHEN EXISTS (
                SELECT 1 FROM inventory i2 WHERE i2.inv_item_sk = cr.cr_item_sk
            ) THEN 1 ELSE 0 END) AS has_inventory_flag
    FROM catalog_returns cr
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN ship_mode sm_cr2 ON cr.cr_ship_mode_sk = sm_cr2.sm_ship_mode_sk
    JOIN ship_mode sm_cr3 ON cr.cr_ship_mode_sk = sm_cr3.sm_ship_mode_sk
    JOIN warehouse w_wh ON cr.cr_warehouse_sk = w_wh.w_warehouse_sk
    JOIN warehouse w_wh2 ON cr.cr_warehouse_sk = w_wh2.w_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w_wh.w_warehouse_sk
    JOIN warehouse w_inv_extra ON inv.inv_warehouse_sk = w_inv_extra.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_ship_mode_sk = sm_cr.sm_ship_mode_sk AND ws.ws_warehouse_sk = w_wh.w_warehouse_sk
    JOIN ship_mode sm_ws2 ON ws.ws_ship_mode_sk = sm_ws2.sm_ship_mode_sk
    JOIN warehouse w_wh3 ON ws.ws_warehouse_sk = w_wh3.w_warehouse_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN web_site ws_site2 ON ws.ws_web_site_sk = ws_site2.web_site_sk
    GROUP BY
        sm_cr.sm_type,
        w_wh.w_state,
        ws_site.web_mkt_desc
)
SELECT
    base.return_ship_type,
    base.return_warehouse_state,
    base.market_description,
    base.total_return_amount,
    base.total_net_profit,
    base.distinct_return_orders,
    base.distinct_sales_orders,
    base.total_inventory_records,
    base.has_inventory_flag,
    ROW_NUMBER() OVER (ORDER BY base.total_return_amount DESC) AS row_num
FROM base
ORDER BY base.total_return_amount DESC
LIMIT 100
