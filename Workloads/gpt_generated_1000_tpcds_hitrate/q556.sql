WITH inv_agg AS (
    SELECT
        inv.inv_warehouse_sk AS warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN warehouse w_i ON inv.inv_warehouse_sk = w_i.w_warehouse_sk
    GROUP BY inv.inv_warehouse_sk
)
SELECT
    ws.ws_web_site_sk,
    ws.ws_sold_date_sk,
    CASE
        WHEN cd_bill.cd_gender = 'M' THEN 'Male'
        WHEN cd_bill.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_category,
    COALESCE(w_sales.w_warehouse_name, w_inv.w_warehouse_name) AS warehouse_name,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(inv_agg.total_qty_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_ticket_count,
    (
        SELECT avg(ws3.ws_quantity)
        FROM web_sales ws3
        WHERE ws3.ws_web_site_sk = ws.ws_web_site_sk
    ) AS avg_quantity_site
FROM web_sales ws
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
FULL OUTER JOIN warehouse w_sales
    ON ws.ws_warehouse_sk = w_sales.w_warehouse_sk
FULL OUTER JOIN warehouse w_inv
    ON w_sales.w_warehouse_sk = w_inv.w_warehouse_sk
LEFT JOIN inv_agg
    ON inv_agg.warehouse_sk = w_inv.w_warehouse_sk
LEFT JOIN store_returns sr
    ON sr.sr_cdemo_sk = cd_bill.cd_demo_sk
CROSS JOIN (SELECT DATE '2002-01-01' AS filter_date) d
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_item_sk = ws.ws_item_sk
      AND sr2.sr_return_quantity > 0
)
  AND ws.ws_quantity > (
    SELECT avg(ws3.ws_quantity)
    FROM web_sales ws3
    WHERE ws3.ws_web_site_sk = ws.ws_web_site_sk
)
GROUP BY
    ws.ws_web_site_sk,
    ws.ws_sold_date_sk,
    cd_bill.cd_gender,
    w_sales.w_warehouse_name,
    w_inv.w_warehouse_name
ORDER BY total_profit DESC
LIMIT 100
