WITH hd AS (
        SELECT hd_demo_sk,
               hd_buy_potential,
               hd_dep_count,
               hd_vehicle_count
        FROM household_demographics
        WHERE hd_dep_count BETWEEN 1 AND 6
          AND hd_vehicle_count >= 0
          AND hd_buy_potential IN ('5001-10000', '>10000')
    ),
    ca_refund AS (
        SELECT ca_address_sk,
               ca_state,
               ca_country
        FROM customer_address
        WHERE ca_state = 'CA'
          AND ca_country = 'United States'
    ),
    ca_store AS (
        SELECT ca_address_sk
        FROM customer_address
    ),
    cr AS (
        SELECT cr_returned_date_sk,
               cr_return_amount,
               cr_return_amt_inc_tax,
               cr_call_center_sk,
               cr_warehouse_sk,
               cr_refunded_addr_sk,
               cr_returning_hdemo_sk
        FROM catalog_returns
        WHERE cr_call_center_sk IN (22, 34)
          AND cr_return_amt_inc_tax > 500
    ),
    ws AS (
        SELECT ws_sold_date_sk,
               ws_order_number,
               ws_quantity,
               ws_sales_price,
               ws_net_paid,
               ws_ext_ship_cost,
               ws_web_page_sk,
               ws_warehouse_sk,
               ws_bill_hdemo_sk,
               ws_bill_addr_sk
        FROM web_sales
        WHERE ws_quantity >= 2
          AND ws_sales_price > 100
          AND ws_ext_ship_cost < 50
    ),
    ss AS (
        SELECT ss_ticket_number,
               ss_quantity,
               ss_sales_price,
               ss_ext_sales_price,
               ss_net_paid,
               ss_store_sk,
               ss_hdemo_sk,
               ss_addr_sk
        FROM store_sales
        WHERE ss_quantity > 1
          AND ss_sales_price BETWEEN 50 AND 500
    ),
    wp AS (
        SELECT wp_web_page_sk,
               wp_link_count,
               wp_image_count,
               wp_type
        FROM web_page
        WHERE wp_link_count >= 20
          AND wp_image_count >= 3
    ),
    cc AS (
        SELECT cc_call_center_sk,
               cc_name,
               cc_state,
               cc_gmt_offset
        FROM call_center
        WHERE cc_state = 'CA'
          AND cc_gmt_offset BETWEEN -8.00 AND -5.00
    ),
    w AS (
        SELECT w_warehouse_sk,
               w_state,
               w_city
        FROM warehouse
        WHERE w_state = 'CA'
    )
SELECT
    cc.cc_name AS call_center_name,
    w.w_city AS warehouse_city,
    hd.hd_buy_potential,
    COUNT(DISTINCT cr.cr_returned_date_sk) AS distinct_return_days,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    AVG(ss.ss_sales_price) AS avg_store_sales_price,
    MIN(ws.ws_ext_ship_cost) AS min_ship_cost,
    MAX(ws.ws_ext_ship_cost) AS max_ship_cost,
    SUM(ws.ws_quantity) AS total_web_quantity
FROM cr
JOIN cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ss ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
WHERE wp.wp_type = 'Content'
GROUP BY
    cc.cc_name,
    w.w_city,
    hd.hd_buy_potential
HAVING SUM(cr.cr_return_amount) > 10000
ORDER BY total_return_amount DESC
LIMIT 100
