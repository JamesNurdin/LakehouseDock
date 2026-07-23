WITH inventory_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
)
SELECT
    i.i_category AS category,
    w_cs.w_warehouse_name AS warehouse_name,
    wp.wp_type AS page_type,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(ia.total_qty_on_hand) AS total_inventory_qty,
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) AS net_total_profit_loss,
    CASE WHEN (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) > 0
        THEN 'Profit'
        ELSE 'Loss'
    END AS profit_flag
FROM item i
JOIN catalog_sales cs
    ON i.i_item_sk = cs.cs_item_sk
JOIN web_sales ws
    ON i.i_item_sk = ws.ws_item_sk
JOIN store_returns sr
    ON i.i_item_sk = sr.sr_item_sk
JOIN inventory_agg ia
    ON i.i_item_sk = ia.inv_item_sk
JOIN warehouse w_cs
    ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN warehouse w_inv
    ON ia.inv_warehouse_sk = w_inv.w_warehouse_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN customer_demographics cd_cs_bill
    ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
JOIN customer_demographics cd_cs_ship
    ON cs.cs_ship_cdemo_sk = cd_cs_ship.cd_demo_sk
JOIN customer_demographics cd_ws_bill
    ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN customer_demographics cd_ws_ship
    ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
GROUP BY
    i.i_category,
    w_cs.w_warehouse_name,
    wp.wp_type
ORDER BY
    net_total_profit_loss DESC
