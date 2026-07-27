WITH sales_a AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        i.i_category AS category,
        sm.sm_type AS ship_mode_type
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE i.i_class_id = 5
      AND i.i_wholesale_cost > 20.00
      AND ca.ca_state = 'CA'
      AND ws_site.web_gmt_offset = -8.00
      AND sm.sm_type = 'AIR'
      AND ws.ws_ext_sales_price > 100.00
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_order_number = ws.ws_order_number
            AND ws2.ws_ext_discount_amt > 5.00
      )
),
sales_b AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        i.i_category AS category,
        sm.sm_type AS ship_mode_type
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE i.i_class_id = 5
      AND i.i_wholesale_cost > 20.00
      AND ca.ca_state = 'CA'
      AND ws_site.web_gmt_offset = -8.00
      AND sm.sm_type = 'RAIL'
      AND ws.ws_ext_sales_price > 100.00
)
SELECT
    u.category,
    u.ship_mode_type,
    SUM(u.ext_sales_price) AS total_sales,
    SUM(u.net_profit) AS total_profit,
    COUNT(DISTINCT u.order_number) AS distinct_orders
FROM (
    SELECT
        ws_order_number AS order_number,
        ws_ext_sales_price AS ext_sales_price,
        ws_net_profit AS net_profit,
        category,
        ship_mode_type
    FROM sales_a
    UNION ALL
    SELECT
        ws_order_number,
        ws_ext_sales_price,
        ws_net_profit,
        category,
        ship_mode_type
    FROM sales_b
) u
GROUP BY u.category, u.ship_mode_type
ORDER BY total_sales DESC
LIMIT 10
