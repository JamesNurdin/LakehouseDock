WITH warehouse_profit AS (
    SELECT ws.ws_warehouse_sk,
           SUM(ws.ws_net_profit) AS warehouse_total_profit
    FROM web_sales ws
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    WHERE d_ship.d_year = 2022
      AND d_ship.d_quarter_name = 'Q4'
    GROUP BY ws.ws_warehouse_sk
    HAVING SUM(ws.ws_net_profit) > 0
),
top_warehouses AS (
    SELECT ws_warehouse_sk
    FROM warehouse_profit
    ORDER BY warehouse_total_profit DESC
    LIMIT 10
)
SELECT w.w_city,
       ca.ca_county,
       wp.wp_type,
       SUM(ws.ws_net_profit) AS total_net_profit,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       AVG(ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_sales_price, 0)) AS avg_discount_ratio,
       COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM web_sales ws
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN top_warehouses tw ON ws.ws_warehouse_sk = tw.ws_warehouse_sk
WHERE d_ship.d_year = 2022
  AND d_ship.d_quarter_name = 'Q4'
GROUP BY w.w_city, ca.ca_county, wp.wp_type
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 5
