WITH bill_sales AS (
    SELECT
        warehouse.w_state AS state,
        'bill' AS sales_type,
        SUM(web_sales.ws_ext_sales_price) AS total_sales
    FROM web_sales
    JOIN customer
        ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
    JOIN warehouse
        ON web_sales.ws_warehouse_sk = warehouse.w_warehouse_sk
    JOIN web_page
        ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
    WHERE customer.c_birth_month = 8
      AND web_page.wp_image_count > 3
    GROUP BY warehouse.w_state
),
ship_sales AS (
    SELECT
        warehouse.w_state AS state,
        'ship' AS sales_type,
        SUM(web_sales.ws_ext_sales_price) AS total_sales
    FROM web_sales
    JOIN customer
        ON web_sales.ws_ship_customer_sk = customer.c_customer_sk
    JOIN warehouse
        ON web_sales.ws_warehouse_sk = warehouse.w_warehouse_sk
    JOIN web_page
        ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
    WHERE customer.c_birth_month = 11
      AND web_page.wp_image_count <= 3
    GROUP BY warehouse.w_state
)
SELECT state, sales_type, total_sales
FROM bill_sales
UNION ALL
SELECT state, sales_type, total_sales
FROM ship_sales
ORDER BY total_sales DESC
LIMIT 100
