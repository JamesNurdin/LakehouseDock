SELECT
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cp.cp_department,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages_viewed,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(ws.ws_net_profit) AS total_web_sales_profit,
    AVG(ws.ws_ext_ship_cost) AS avg_web_ship_cost
FROM
    store_returns sr
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer c_page
    ON wp.wp_customer_sk = c_page.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
      AND ws2.ws_ext_ship_cost > 500
)
GROUP BY
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cp.cp_department
ORDER BY
    total_store_net_loss DESC,
    total_catalog_net_loss DESC
LIMIT 100
