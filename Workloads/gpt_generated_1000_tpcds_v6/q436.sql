/* Goal: Identify high‑value income bands for customers whose email address belongs to the 'example.com' domain and whose first name starts with 'A'. The query extracts the email domain, builds a full name, filters on household dependence, uses string pattern matching, includes a scalar subquery for average net paid, an EXISTS subquery for costly shipments, counts distinct customers, and returns the top 100 groups by total net paid. */
WITH filtered_sales AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_net_paid,
        ws.ws_wholesale_cost,
        ws.ws_sold_date_sk
    FROM web_sales ws
    WHERE ws.ws_wholesale_cost > 20
)
SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(fs.ws_net_paid) AS total_net_paid,
    AVG(fs.ws_net_paid) AS avg_net_paid,
    REGEXP_EXTRACT(c.c_email_address, '@(.+)$') AS email_domain,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    SUBSTRING(c.c_login, 1, 3) AS login_prefix
FROM filtered_sales fs
JOIN customer c
    ON fs.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    AND c.c_first_name LIKE 'A%'
    AND hd.hd_dep_count >= 1
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_ship_customer_sk = c.c_customer_sk
          AND ws2.ws_wholesale_cost > 50
          AND ws2.ws_sold_date_sk = fs.ws_sold_date_sk
    )
GROUP BY
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    REGEXP_EXTRACT(c.c_email_address, '@(.+)$'),
    CONCAT(c.c_first_name, ' ', c.c_last_name),
    SUBSTRING(c.c_login, 1, 3)
HAVING
    SUM(fs.ws_net_paid) > (
        SELECT AVG(ws3.ws_net_paid)
        FROM web_sales ws3
    )
ORDER BY total_net_paid DESC
LIMIT 100
