WITH segment_a AS (
    SELECT
        ca.ca_state AS state,
        'Preferred_1970s' AS segment,
        COUNT(DISTINCT c.c_customer_sk) AS cust_count,
        MIN(c.c_last_review_date) AS earliest_review,
        (
            SELECT COUNT(DISTINCT ca2.ca_address_id)
            FROM customer_address ca2
            WHERE ca2.ca_state = ca.ca_state
        ) AS total_addresses_in_state
    FROM customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1970 AND 1979
      AND c.c_last_review_date IN (2452393, 2452295)
      AND ca.ca_location_type = 'condo'
    GROUP BY ca.ca_state
),
segment_b AS (
    SELECT
        ca.ca_state AS state,
        'NonPreferred_1990s' AS segment,
        COUNT(DISTINCT c.c_customer_sk) AS cust_count,
        MIN(c.c_last_review_date) AS earliest_review,
        (
            SELECT COUNT(DISTINCT ca2.ca_address_id)
            FROM customer_address ca2
            WHERE ca2.ca_state = ca.ca_state
        ) AS total_addresses_in_state
    FROM customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'N'
      AND c.c_birth_year BETWEEN 1990 AND 1999
      AND c.c_last_review_date IN (2452557, 2452416)
      AND EXISTS (
          SELECT 1
          FROM customer_address ca3
          WHERE ca3.ca_state = ca.ca_state
            AND ca3.ca_location_type = 'apartment'
      )
    GROUP BY ca.ca_state
)
SELECT *
FROM segment_a
UNION ALL
SELECT *
FROM segment_b
ORDER BY state, segment
LIMIT 100
