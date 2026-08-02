/*
  Goal: Identify the top stores (by total sales) that have large floor space, whose store names match a specific pattern, and whose street type ends with 'Road'.
  The query demonstrates string processing using REGEXP_LIKE, REGEXP_EXTRACT, LIKE, and CONCAT, filters store_sales rows via an IN subquery on store, aggregates sales and profit metrics, and returns the results ordered by total sales.
*/
WITH filtered_sales AS (
    SELECT ss.*
    FROM store_sales ss
    WHERE ss.ss_store_sk IN (
        SELECT s.s_store_sk
        FROM store s
        WHERE s.s_floor_space > 8000000
    )
)
SELECT
    s.s_store_id,
    CONCAT(s.s_city, ', ', s.s_state) AS location,
    REGEXP_EXTRACT(s.s_street_name, '(\\d+)', 1) AS street_number_extracted,
    COUNT(DISTINCT fs.ss_ticket_number) AS unique_tickets,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    AVG(fs.ss_net_profit) AS avg_profit
FROM filtered_sales fs
JOIN store s
    ON fs.ss_store_sk = s.s_store_sk
WHERE
    REGEXP_LIKE(s.s_store_name, '^Store[[:space:]]\\d+$')
    AND s.s_street_type LIKE '%Road%'
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_street_name,
    REGEXP_EXTRACT(s.s_street_name, '(\\d+)', 1)
ORDER BY total_sales DESC
LIMIT 100
