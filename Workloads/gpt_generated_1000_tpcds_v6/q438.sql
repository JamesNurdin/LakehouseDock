WITH unified_events AS (
   SELECT
       c.c_customer_id,
       c.c_salutation,
       d.d_year AS year,
       d.d_qoy AS quarter,
       'SHIPTO' AS event_type,
       d.d_date AS event_date
   FROM customer c
   JOIN date_dim d
     ON c.c_first_shipto_date_sk = d.d_date_sk
   WHERE c.c_salutation IN ('Mrs.', 'Ms.', 'Dr.')
     AND c.c_preferred_cust_flag = 'Y'
     AND c.c_birth_year BETWEEN 1970 AND 1990
     AND d.d_year = 2022
     AND d.d_qoy = 2
   UNION ALL
   SELECT
       c.c_customer_id,
       c.c_salutation,
       d.d_year AS year,
       d.d_qoy AS quarter,
       'SALES' AS event_type,
       d.d_date AS event_date
   FROM customer c
   JOIN date_dim d
     ON c.c_first_sales_date_sk = d.d_date_sk
   WHERE c.c_salutation IN ('Mrs.', 'Ms.', 'Dr.')
     AND c.c_preferred_cust_flag = 'Y'
     AND c.c_birth_year BETWEEN 1970 AND 1990
     AND d.d_year = 2022
     AND d.d_qoy = 2
)
SELECT
    year,
    quarter,
    event_type,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    MIN(event_date) AS first_event,
    MAX(event_date) AS last_event,
    (SELECT COUNT(*) FROM customer WHERE c_preferred_cust_flag = 'Y') AS total_preferred_customers
FROM unified_events
GROUP BY GROUPING SETS (
    (year, quarter, event_type),
    (year, quarter),
    (year),
    ()
)
HAVING COUNT(DISTINCT c_customer_id) > 10
ORDER BY year, quarter, event_type NULLS LAST
