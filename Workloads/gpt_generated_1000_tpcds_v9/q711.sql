WITH base AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        cc.cc_name AS call_center_name,
        ss.ss_net_paid,
        sr.sr_net_loss,
        cr.cr_net_loss,
        ws.ws_net_paid,
        ss.ss_customer_sk,
        i.inv_quantity_on_hand,
        w.w_warehouse_sk
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_quantity_on_hand > 600
    JOIN web_sales ws
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_suite_number = 'Suite P'
        AND ca.ca_gmt_offset = -5.00
        AND cc.cc_state = 'CA'
        AND ss.ss_quantity >= 3
)
SELECT
    b.w_warehouse_id,
    b.w_city,
    b.call_center_name,
    SUM(b.ss_net_paid) AS total_store_sales_net_paid,
    SUM(b.sr_net_loss) AS total_store_returns_net_loss,
    SUM(b.cr_net_loss) AS total_catalog_returns_net_loss,
    SUM(b.ws_net_paid) AS total_web_sales_net_paid,
    COUNT(DISTINCT b.ss_customer_sk) AS unique_store_customers,
    COALESCE(SUM(b.inv_quantity_on_hand), 0) AS total_inventory_quantity,
    (
        SELECT AVG(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = b.w_warehouse_sk
    ) AS avg_web_sales_net_paid_warehouse
FROM base b
GROUP BY
    b.w_warehouse_id,
    b.w_city,
    b.call_center_name,
    b.w_warehouse_sk
HAVING
    SUM(b.ss_net_paid) > 10000
ORDER BY
    total_store_sales_net_paid DESC
LIMIT 100
