/*
Goal: Analyze catalog return performance by ship mode for customers whose email ends with ".com" and first name starts with "A". The query joins returns, customers, ship modes, and store sales, extracts domain information with regex, applies LIKE pattern matching, concatenates and substrings strings, includes a CASE expression, uses DISTINCT, an EXISTS subquery, a scalar subquery, samples the returns table, aggregates metrics, orders by total return amount, and limits the result.
*/
WITH filtered_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM customer c
    WHERE REGEXP_LIKE(c.c_email_address, '\\.com$')
      AND REGEXP_LIKE(c.c_first_name, '^A')
      AND c.c_birth_year BETWEEN 1970 AND 1990
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_type,
    sm.sm_carrier,
    CONCAT('Ship_', sm.sm_ship_mode_id) AS ship_mode_code,
    SUBSTRING(sm.sm_carrier FROM 1 FOR 5) AS carrier_prefix,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_return_total,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_net_loss,
    AVG(ss.ss_net_paid) AS avg_store_sales_net_paid,
    (SELECT AVG(ss_inner.ss_net_paid) FROM store_sales ss_inner) AS overall_avg_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    CASE
        WHEN REGEXP_LIKE(c.c_email_address, '^.*@example\\.com$') THEN 'Example.com'
        ELSE 'Other'
    END AS email_category,
    SUBSTRING(c.c_first_name || ' ' || c.c_last_name FROM 1 FOR 10) AS short_name,
    REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1) AS email_domain
FROM
    catalog_returns cr TABLESAMPLE BERNOULLI (20)
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_sales ss
    ON ss.ss_customer_sk = cr.cr_refunded_customer_sk
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE
    c.c_customer_sk IN (SELECT c_customer_sk FROM filtered_customers)
    AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = c.c_customer_sk
          AND ss2.ss_sold_date_sk > 2450000
    )
    AND cr.cr_return_amount > 50
    AND REGEXP_LIKE(c.c_email_address, '^.*@example\\.com$')
    AND LOWER(c.c_last_name) LIKE '%son'
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_type,
    sm.sm_carrier,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address
ORDER BY
    total_return_amount DESC
LIMIT 100
