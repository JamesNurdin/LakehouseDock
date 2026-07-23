WITH agg AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        p.p_promo_name,
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        CASE
            WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH'
            WHEN SUM(ws.ws_net_profit) > 50000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM
        web_sales ws
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
        JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
        JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        cp.cp_department = 'Electronics'
        AND wp.wp_char_count > 4000
        AND cd_bill.cd_gender = 'M'
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        p.p_promo_name,
        w.w_warehouse_name
    HAVING
        SUM(ws.ws_net_profit) > 10000
)
SELECT
    cp_catalog_page_id,
    cp_catalog_page_number,
    p_promo_name,
    w_warehouse_name,
    total_net_profit,
    total_return_amount,
    total_inventory_qty,
    profit_category,
    ROW_NUMBER() OVER (PARTITION BY cp_catalog_page_id ORDER BY total_net_profit DESC) AS rn
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100
