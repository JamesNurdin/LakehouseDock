WITH morning_sales AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_ext_sales_price AS ext_sales_price,
        i.i_product_name AS product_name,
        ca.ca_city AS city,
        hd.hd_buy_potential AS buy_potential,
        td.t_hour AS hour
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 12
      AND i.i_manager_id = 64
      AND ws.ws_ext_sales_price > 1000
),
afternoon_sales AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_ext_sales_price AS ext_sales_price,
        i.i_product_name AS product_name,
        ca.ca_city AS city,
        hd.hd_buy_potential AS buy_potential,
        td.t_hour AS hour
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 13 AND 17
      AND i.i_container = 'Unknown'
      AND ws.ws_ext_sales_price BETWEEN 500 AND 1500
)
SELECT
    order_number,
    ext_sales_price,
    product_name,
    city,
    buy_potential,
    hour
FROM morning_sales
UNION ALL
SELECT
    order_number,
    ext_sales_price,
    product_name,
    city,
    buy_potential,
    hour
FROM afternoon_sales
ORDER BY ext_sales_price DESC
LIMIT 100
