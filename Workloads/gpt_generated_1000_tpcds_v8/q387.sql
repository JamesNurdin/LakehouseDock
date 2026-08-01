WITH billed AS (
    SELECT
        ws.ws_order_number AS order_num,
        ws.ws_bill_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        hd.hd_vehicle_count AS vehicle_cnt,
        ws.ws_ext_sales_price AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank_by_sales,
        ws.ws_web_page_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN LATERAL (
        SELECT wp_type
        FROM web_page wp
        WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
        LIMIT 1
    ) wp ON true
    WHERE c.c_birth_country = 'MONACO'
      AND NOT EXISTS (
          SELECT 1
          FROM web_page wp2
          WHERE wp2.wp_web_page_sk = ws.ws_web_page_sk
            AND wp2.wp_type = 'promo'
      )
)
SELECT
    u.order_num,
    u.customer_sk,
    u.first_name,
    u.last_name,
    u.vehicle_cnt,
    u.total_sales,
    u.rank_by_sales
FROM (
    SELECT
        b.order_num,
        b.customer_sk,
        b.first_name,
        b.last_name,
        b.vehicle_cnt,
        b.total_sales,
        b.rank_by_sales
    FROM billed b

    UNION

    SELECT
        ws.ws_order_number AS order_num,
        ws.ws_ship_customer_sk AS customer_sk,
        c2.c_first_name AS first_name,
        c2.c_last_name AS last_name,
        hd2.hd_vehicle_count AS vehicle_cnt,
        ws.ws_ext_sales_price AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_customer_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank_by_sales
    FROM web_sales ws
    JOIN customer c2 ON ws.ws_ship_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd2 ON ws.ws_ship_hdemo_sk = hd2.hd_demo_sk
    WHERE hd2.hd_vehicle_count > 0
) u
WHERE u.order_num IN (
    SELECT b.order_num FROM billed b
    INTERSECT
    SELECT ws.ws_order_number FROM web_sales ws WHERE ws.ws_quantity > 10
)
ORDER BY u.total_sales DESC, u.order_num
LIMIT 100
