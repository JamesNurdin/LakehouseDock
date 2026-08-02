WITH aggregated_sales AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        wp.wp_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        CASE
            WHEN SUM(ws.ws_net_profit) > 5000 THEN 'HIGH'
            WHEN SUM(ws.ws_net_profit) BETWEEN 1000 AND 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        ws.ws_sales_price > 20.00
        AND ws.ws_net_paid_inc_ship_tax >= 1000.00
        AND wp.wp_autogen_flag = 'Y'
        AND wp.wp_rec_start_date >= DATE '2001-01-01'
        AND c.c_birth_year BETWEEN 1960 AND 1990
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        wp.wp_type
    HAVING SUM(ws.ws_ext_sales_price) > 5000
)
SELECT
    a.customer_sk,
    a.c_first_name,
    a.c_last_name,
    a.wp_type,
    a.total_sales,
    a.total_profit,
    a.total_quantity,
    a.profit_category,
    avg_sales.avg_sales_price,
    a.total_sales / avg_sales.avg_sales_price AS sales_to_avg_ratio
FROM aggregated_sales a
CROSS JOIN (
    SELECT AVG(ws_ext_sales_price) AS avg_sales_price FROM web_sales
) avg_sales
WHERE NOT EXISTS (
    SELECT 1
    FROM (
        SELECT ws.ws_ship_customer_sk AS cust_sk FROM web_sales ws WHERE ws.ws_net_profit > 2000
        INTERSECT
        SELECT wp.wp_customer_sk AS cust_sk FROM web_page wp WHERE wp.wp_autogen_flag = 'N'
    ) intersect_customers
    WHERE intersect_customers.cust_sk = a.customer_sk
)
ORDER BY a.total_profit DESC
LIMIT 100
