WITH customer_page_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        ws.ws_web_page_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_wholesale_cost) AS avg_wholesale_cost
    FROM tpcds.customer c
    JOIN tpcds.web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1950 AND 1995
        AND c.c_preferred_cust_flag = 'Y'
        AND ws.ws_ext_discount_amt > 0
        AND ws.ws_ext_ship_cost < 2000
        AND ws.ws_ext_sales_price > 0
        AND ws.ws_quantity > 0
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        ws.ws_web_page_sk
)
SELECT
    wp.wp_type,
    COUNT(*) AS num_customers,
    SUM(cps.total_sales) AS sum_total_sales,
    AVG(cps.total_sales) AS avg_total_sales,
    (SELECT SUM(ws3.ws_net_paid)
       FROM tpcds.web_sales ws3
       WHERE ws3.ws_web_page_sk = wp.wp_web_page_sk) AS total_net_paid_for_page
FROM customer_page_sales cps
JOIN tpcds.web_page wp ON wp.wp_web_page_sk = cps.ws_web_page_sk
WHERE EXISTS (
        SELECT 1
        FROM tpcds.web_page wp2
        WHERE wp2.wp_web_page_sk = cps.ws_web_page_sk
          AND wp2.wp_link_count >= 5
          AND wp2.wp_char_count BETWEEN 500 AND 2000
    )
    AND cps.total_sales > 1000
    AND cps.avg_wholesale_cost < 70
GROUP BY
    wp.wp_type,
    wp.wp_web_page_sk
HAVING SUM(cps.total_sales) > 5000
ORDER BY sum_total_sales DESC
LIMIT 100
