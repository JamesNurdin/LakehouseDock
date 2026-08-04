WITH high_value_orders AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_net_paid_inc_ship > 5000
),
discounted_orders AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_ext_discount_amt > 1000
),
common_orders AS (
    SELECT ws_order_number
    FROM high_value_orders
    INTERSECT
    SELECT ws_order_number
    FROM discounted_orders
)
SELECT
    w.w_state,
    s.web_state,
    c.c_preferred_cust_flag,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid_inc_ship) AS total_paid_inc_ship,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(ws.ws_net_paid_inc_ship) AS min_paid,
    MAX(ws.ws_net_paid_inc_ship) AS max_paid
FROM
    customer c
    INNER JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    FULL OUTER JOIN web_site s
        ON ws.ws_web_site_sk = s.web_site_sk
WHERE
    ws.ws_net_paid_inc_ship BETWEEN 3000 AND 10000
    AND ws.ws_ext_discount_amt > 200
    AND w.w_zip = '33604'
    AND c.c_last_review_date >= 2452400
    AND ws.ws_order_number IN (SELECT ws_order_number FROM common_orders)
    AND EXISTS (
        SELECT 1
        FROM customer c2
        WHERE c2.c_customer_sk = c.c_customer_sk
          AND c2.c_birth_year BETWEEN 1960 AND 1970
    )
GROUP BY
    w.w_state,
    s.web_state,
    c.c_preferred_cust_flag
ORDER BY total_paid_inc_ship DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
