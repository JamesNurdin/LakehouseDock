WITH billing_sales AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ca.ca_country = 'United States'
      AND hd.hd_vehicle_count >= 2
    GROUP BY w.w_warehouse_id, w.w_city
),
shipping_sales AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ca.ca_city = 'Fairview'
      AND hd.hd_vehicle_count <= 1
    GROUP BY w.w_warehouse_id, w.w_city
)
SELECT DISTINCT *
FROM (
    SELECT * FROM billing_sales
    UNION ALL
    SELECT * FROM shipping_sales
) combined
ORDER BY total_sales DESC
LIMIT 100
