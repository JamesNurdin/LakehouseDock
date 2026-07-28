WITH store_spending AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(ss.ss_net_paid) AS total_spent,
        'store' AS channel
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY c.c_customer_id
    HAVING SUM(ss.ss_net_paid) > 10000
),
web_spending AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        'web' AS channel
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY c.c_customer_id
    HAVING SUM(ws.ws_net_paid) > 10000
)
SELECT DISTINCT
    customer_id,
    total_spent,
    channel
FROM (
    SELECT * FROM store_spending
    UNION ALL
    SELECT * FROM web_spending
) AS combined
ORDER BY total_spent DESC
LIMIT 100
