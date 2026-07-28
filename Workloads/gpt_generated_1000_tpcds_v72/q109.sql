WITH customers AS (
    SELECT
        c.c_customer_id AS entity_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS entity_name,
        'Customer' AS entity_type,
        d.d_year AS year,
        ca.ca_city AS location
    FROM tpcds.customer c
    INNER JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    INNER JOIN tpcds.date_dim d
        ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE ca.ca_county LIKE '%County%'
      AND d.d_fy_year = 1905
),
stores AS (
    SELECT
        s.s_store_id AS entity_id,
        s.s_store_name AS entity_name,
        'Store' AS entity_type,
        d.d_year AS year,
        s.s_city AS location
    FROM tpcds.store s
    INNER JOIN tpcds.date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
      AND d.d_fy_year = 1905
)
SELECT
    combined.entity_type,
    COUNT(*) AS cnt
FROM (
    SELECT * FROM customers
    UNION ALL
    SELECT * FROM stores
) AS combined
GROUP BY combined.entity_type
HAVING COUNT(*) > 5
ORDER BY cnt DESC
LIMIT 100
