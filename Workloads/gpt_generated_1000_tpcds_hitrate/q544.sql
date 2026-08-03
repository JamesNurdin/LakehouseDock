WITH recent_customers AS (
    SELECT c_customer_sk, c_customer_id, c_last_review_date
    FROM tpcds.customer
    WHERE c_last_review_date > 2452500
),
order_exclusion AS (
    SELECT ws_order_number
    FROM tpcds.web_sales
    WHERE ws_ext_sales_price > 5000
    EXCEPT
    SELECT ws_order_number
    FROM tpcds.web_sales
    WHERE ws_ext_sales_price < 1000
)
SELECT
    CONCAT(w.w_city, ', ', w.w_state) AS location,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_order_cnt,
    COUNT(DISTINCT rc.c_customer_id) AS distinct_customer_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    AVG(ws.ws_ext_discount_amt) AS avg_discount
FROM tpcds.warehouse w
FULL OUTER JOIN tpcds.web_sales ws
    ON w.w_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN recent_customers rc
    ON ws.ws_bill_customer_sk = rc.c_customer_sk
LEFT JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE (
        wp.wp_url IS NOT NULL
        AND REGEXP_LIKE(wp.wp_url, '^https?://.*\\.example\\.com')
    )
    OR (w.w_street_name LIKE '%North%')
    AND ws.ws_order_number IN (SELECT ws_order_number FROM order_exclusion)
    AND ws.ws_ext_discount_amt > (
        SELECT AVG(ws2.ws_ext_discount_amt)
        FROM tpcds.web_sales ws2
    )
GROUP BY
    CONCAT(w.w_city, ', ', w.w_state),
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1)
HAVING COUNT(DISTINCT ws.ws_order_number) > 0
ORDER BY total_sales DESC
LIMIT 100
