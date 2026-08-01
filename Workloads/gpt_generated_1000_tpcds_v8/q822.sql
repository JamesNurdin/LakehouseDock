WITH
    store_sales_2020 AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            SUM(ss.ss_net_paid) AS total_store_spent,
            CASE WHEN SUM(ss.ss_net_paid) > 20000 THEN 'High' ELSE 'Low' END AS spend_category
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2020
          AND ss.ss_net_paid > 0
          AND c.c_customer_sk IN (
                SELECT sr.sr_customer_sk
                FROM store_returns sr
                WHERE sr.sr_net_loss > 0
          )
        GROUP BY c.c_customer_sk, c.c_customer_id
        HAVING SUM(ss.ss_net_paid) > 5000
    ),
    web_sales_2020 AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            SUM(ws.ws_net_paid) AS total_web_spent,
            CASE WHEN SUM(ws.ws_net_paid) > 20000 THEN 'High' ELSE 'Low' END AS spend_category
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        WHERE d.d_year = 2020
          AND ws.ws_net_paid > 0
          AND EXISTS (
                SELECT 1
                FROM web_site ws2
                WHERE ws2.web_site_sk = ws.ws_web_site_sk
                  AND ws2.web_state = 'CA'
          )
        GROUP BY c.c_customer_sk, c.c_customer_id
        HAVING SUM(ws.ws_net_paid) > 5000
    ),
    intersect_customers AS (
        SELECT c_customer_sk, c_customer_id FROM store_sales_2020
        INTERSECT
        SELECT c_customer_sk, c_customer_id FROM web_sales_2020
    )
SELECT
    ic.c_customer_id,
    ic.c_customer_sk,
    ss.total_store_spent,
    ws.total_web_spent,
    CASE
        WHEN ss.total_store_spent > ws.total_web_spent THEN 'Store Higher'
        WHEN ss.total_store_spent < ws.total_web_spent THEN 'Web Higher'
        ELSE 'Equal'
    END AS higher_channel,
    (
        SELECT COUNT(*)
        FROM store_returns sr
        WHERE sr.sr_customer_sk = ic.c_customer_sk
    ) AS store_return_count,
    recent_sales.recent_date
FROM intersect_customers ic
LEFT JOIN store_sales_2020 ss ON ss.c_customer_sk = ic.c_customer_sk
LEFT JOIN web_sales_2020 ws ON ws.c_customer_sk = ic.c_customer_sk
CROSS JOIN LATERAL (
    SELECT d.d_date AS recent_date
    FROM store_sales s
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE s.ss_customer_sk = ic.c_customer_sk
    ORDER BY d.d_date DESC
    LIMIT 1
) AS recent_sales
ORDER BY higher_channel, ic.c_customer_id
OFFSET 0 LIMIT 100
