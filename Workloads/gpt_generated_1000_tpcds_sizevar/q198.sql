WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_web_site_sk IN (
        SELECT DISTINCT ws2.ws_web_site_sk
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_ext_sales_price > 5000
    )
)
SELECT
    ws.ws_order_number,
    web_site.web_name,
    web_site.web_country,
    sm.sm_type,
    w.w_state,
    ca_bill.ca_city          AS bill_city,
    ca_ship.ca_city          AS ship_city,
    wp.wp_type,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(*)                    AS txn_count,
    (
        SELECT SUM(ws_sub.ws_quantity)
        FROM tpcds.web_sales ws_sub
        WHERE ws_sub.ws_order_number = ws.ws_order_number
    ) AS total_qty_per_order
FROM filtered_sales ws
JOIN tpcds.customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.ship_mode sm_alt
    ON ws.ws_ship_mode_sk = sm_alt.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.warehouse w_alt
    ON ws.ws_warehouse_sk = w_alt.w_warehouse_sk
JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_page wp_alt
    ON ws.ws_web_page_sk = wp_alt.wp_web_page_sk
JOIN tpcds.web_site web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
JOIN tpcds.web_site web_site_alt
    ON ws.ws_web_site_sk = web_site_alt.web_site_sk
GROUP BY
    ws.ws_order_number,
    web_site.web_name,
    web_site.web_country,
    sm.sm_type,
    w.w_state,
    ca_bill.ca_city,
    ca_ship.ca_city,
    wp.wp_type
ORDER BY total_sales DESC
LIMIT 100
