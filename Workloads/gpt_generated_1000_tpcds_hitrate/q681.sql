WITH high_stock_inventory AS (
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 800
)
SELECT
    i.i_category AS item_category,
    sm.sm_type AS ship_type,
    CASE WHEN SUM(ss.ss_net_profit + ws.ws_net_profit - cr.cr_net_loss) > 5000 THEN 'High' ELSE 'Low' END AS profit_level,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(ss.ss_quantity + ws.ws_quantity) AS total_quantity_sold
FROM
    item i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_cr_refund ON cr.cr_refunded_cdemo_sk = cd_cr_refund.cd_demo_sk
    JOIN customer_demographics cd_cr_returning ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
WHERE
    i.i_item_sk IN (SELECT inv_item_sk FROM high_stock_inventory)
GROUP BY GROUPING SETS (
    (i.i_category, sm.sm_type),
    (i.i_category),
    ()
)
HAVING
    SUM(ss.ss_net_profit + ws.ws_net_profit - cr.cr_net_loss) > 1000
ORDER BY
    item_category,
    ship_type
LIMIT 100
