WITH 
    orders_a AS (
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_list_price > 150
    ),
    orders_b AS (
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_quantity > 5
    ),
    excluded_orders AS (
        SELECT ws_order_number
        FROM orders_a
        EXCEPT
        SELECT ws_order_number
        FROM orders_b
    ),
    intersect_orders AS (
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_ext_discount_amt > 0
        INTERSECT
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_coupon_amt > 0
    ),
    filtered_sales AS (
        SELECT ws.*
        FROM web_sales ws
        JOIN web_site wsite
            ON ws.ws_web_site_sk = wsite.web_site_sk
        WHERE ws.ws_list_price > 50
          AND ws.ws_sales_price < 200
          AND ws.ws_quantity BETWEEN 1 AND 10
          AND ws.ws_ship_mode_sk IN (1, 2, 3)
          AND wsite.web_state = 'CA'
          AND wsite.web_mkt_class LIKE '%New%'
          AND ws.ws_order_number IN (SELECT ws_order_number FROM excluded_orders)
          AND ws.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
    )
SELECT 
    fs.ws_bill_customer_sk,
    wsite.web_site_id,
    COUNT(*) AS order_cnt,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    AVG(fs.ws_sales_price) AS avg_sales_price,
    MIN(fs.ws_ext_sales_price) AS min_sales,
    MAX(fs.ws_ext_sales_price) AS max_sales,
    (SELECT COUNT(*)
     FROM web_sales ws_inner
     WHERE ws_inner.ws_bill_customer_sk = fs.ws_bill_customer_sk) AS total_orders_by_customer,
    ROW_NUMBER() OVER (ORDER BY SUM(fs.ws_ext_sales_price) DESC) AS rn
FROM filtered_sales fs
JOIN web_site wsite
    ON fs.ws_web_site_sk = wsite.web_site_sk
GROUP BY 
    fs.ws_bill_customer_sk,
    wsite.web_site_id
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
