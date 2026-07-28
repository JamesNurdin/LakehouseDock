WITH ws AS (
        SELECT
            ws_order_number,
            ws_warehouse_sk,
            ws_web_site_sk,
            ws_bill_hdemo_sk,
            ws_bill_addr_sk,
            ws_sales_price,
            ws_wholesale_cost,
            ws_net_paid,
            ws_quantity
        FROM web_sales
        WHERE ws_sales_price > 50
          AND ws_wholesale_cost < 30
          AND ws_quantity >= 1
    ),
    wh AS (
        SELECT w_warehouse_sk, w_warehouse_name, w_state
        FROM warehouse
        WHERE w_state = 'CA'
    ),
    wsd AS (
        SELECT hd_demo_sk, hd_vehicle_count, hd_dep_count
        FROM household_demographics
        WHERE hd_vehicle_count >= 2
    ),
    ca AS (
        SELECT ca_address_sk, ca_city, ca_state
        FROM customer_address
        WHERE ca_city = 'York'
    ),
    ws_site AS (
        SELECT web_site_sk, web_name
        FROM web_site
        WHERE web_name = 'OnlineStore'
    ),
    cr AS (
        SELECT cr_order_number, cr_warehouse_sk, cr_reason_sk, cr_return_amount
        FROM catalog_returns
        WHERE cr_return_amount > 0
    ),
    r AS (
        SELECT r_reason_sk, r_reason_desc
        FROM reason
        WHERE r_reason_desc = 'Damaged'
    )
SELECT
    wh.w_warehouse_name,
    ws_site.web_name,
    r.r_reason_desc,
    ca.ca_state,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MIN(ws.ws_sales_price) AS min_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price
FROM ws
JOIN wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
JOIN ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN wsd ON ws.ws_bill_hdemo_sk = wsd.hd_demo_sk
JOIN ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN cr ON wh.w_warehouse_sk = cr.cr_warehouse_sk
JOIN r ON cr.cr_reason_sk = r.r_reason_sk
GROUP BY
    wh.w_warehouse_name,
    ws_site.web_name,
    r.r_reason_desc,
    ca.ca_state
ORDER BY total_net_paid DESC
LIMIT 100
