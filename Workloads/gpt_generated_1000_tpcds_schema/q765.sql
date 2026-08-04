WITH ws_w AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_warehouse_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_wholesale_cost,
        ws.ws_ext_sales_price,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_net_profit,
        ws.ws_coupon_amt,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_gmt_offset
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_ext_wholesale_cost > 1000
      AND ws.ws_ext_sales_price BETWEEN 2000 AND 5000
      AND ws.ws_net_profit > 0
      AND ws.ws_coupon_amt = 0
      AND ws.ws_quantity >= 1
      AND ws.ws_sold_date_sk BETWEEN 2450800 AND 2451200
),

wp_filtered AS (
    SELECT wp_web_page_sk, wp_type, wp_link_count, wp_char_count
    FROM web_page
    WHERE wp_type IN ('article', 'category')
      AND wp_link_count > 10
      AND wp_char_count BETWEEN 2000 AND 3500
),

inv_full AS (
    SELECT inv_item_sk, inv_quantity_on_hand, inv_warehouse_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 0
),

max_net_paid AS (
    SELECT MAX(ws_net_paid_inc_ship_tax) AS max_paid FROM web_sales
),

subq1 AS (
    SELECT ws.ws_order_number AS order_num
    FROM ws_w ws
    JOIN wp_filtered wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_wholesale_cost < (SELECT max_paid FROM max_net_paid)
),

subq2 AS (
    SELECT ws.ws_order_number AS order_num
    FROM ws_w ws
    JOIN inv_full i ON i.inv_warehouse_sk = ws.ws_warehouse_sk
    WHERE i.inv_quantity_on_hand > 5
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_net_paid_inc_ship_tax,
    wp.wp_type,
    w.w_warehouse_name,
    inv.inv_quantity_on_hand,
    RANK() OVER (PARTITION BY w.w_state ORDER BY ws.ws_net_paid_inc_ship_tax DESC) AS state_rank,
    ROW_NUMBER() OVER (ORDER BY ws.ws_net_paid_inc_ship_tax DESC) AS global_rownum,
    CASE
        WHEN ws.ws_net_profit > 1000 THEN 'HIGH'
        WHEN ws.ws_net_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    lt.avg_quantity_last_7_days
FROM ws_w ws
JOIN wp_filtered wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
FULL OUTER JOIN (
    SELECT inv_item_sk, inv_quantity_on_hand, inv_warehouse_sk
    FROM inv_full
) inv ON inv.inv_warehouse_sk = ws.ws_warehouse_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
CROSS JOIN LATERAL (
    SELECT AVG(ws2.ws_quantity) AS avg_quantity_last_7_days
    FROM web_sales ws2
    WHERE ws2.ws_warehouse_sk = ws.ws_warehouse_sk
      AND ws2.ws_sold_date_sk BETWEEN ws.ws_sold_date_sk - 7 AND ws.ws_sold_date_sk
) lt
WHERE ws.ws_order_number IN (
    SELECT order_num FROM subq1
    INTERSECT
    SELECT order_num FROM subq2
)
ORDER BY ws.ws_net_paid_inc_ship_tax DESC
LIMIT 100
