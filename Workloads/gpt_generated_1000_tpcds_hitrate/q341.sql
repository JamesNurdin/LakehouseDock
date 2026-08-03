WITH recent_customers AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_last_review_date
    FROM customer
    WHERE c_last_review_date >= 2452500
)
SELECT
    cust.c_customer_sk,
    cust.c_first_name,
    cust.c_last_name,
    src.sales_category,
    src.total_net_paid,
    src.avg_net_profit
FROM recent_customers AS cust
JOIN (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        CASE WHEN ws.ws_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_autogen_flag = 'Y'
    GROUP BY ws.ws_bill_customer_sk,
             CASE WHEN ws.ws_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END
    UNION ALL
    SELECT
        ws.ws_ship_customer_sk AS cust_sk,
        CASE WHEN ws.ws_net_profit > 500 THEN 'MEDIUM' ELSE 'LOW' END AS sales_category,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_char_count > 2000
    GROUP BY ws.ws_ship_customer_sk,
             CASE WHEN ws.ws_net_profit > 500 THEN 'MEDIUM' ELSE 'LOW' END
) src ON cust.c_customer_sk = src.cust_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = cust.c_customer_sk
      AND ws2.ws_wholesale_cost > 50
)
ORDER BY src.total_net_paid DESC
LIMIT 100
