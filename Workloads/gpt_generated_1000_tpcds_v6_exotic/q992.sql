WITH state_offsets AS (
    SELECT ca_state, MAX(ca_gmt_offset) AS max_offset
    FROM customer_address
    GROUP BY ca_state
)
SELECT
    ca.ca_state,
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_cnt,
    AVG(c.c_birth_year) AS avg_birth_year,
    MIN(c.c_birth_year) AS youngest_birth_year,
    MAX(c.c_birth_year) AS oldest_birth_year,
    (
        SELECT max_offset
        FROM state_offsets so
        WHERE so.ca_state = ca.ca_state
    ) AS state_max_offset
FROM customer c
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
WHERE c.c_birth_day = 28
  AND c.c_first_sales_date_sk BETWEEN 2449000 AND 2451000
  AND ca.ca_street_name LIKE '%Hill%'
GROUP BY ca.ca_state, ca.ca_city
ORDER BY customer_cnt DESC
LIMIT 100
