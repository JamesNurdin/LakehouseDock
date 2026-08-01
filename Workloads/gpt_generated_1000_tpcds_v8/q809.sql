WITH
  base_apartments AS (
    SELECT
      c.c_customer_id,
      c.c_last_name,
      ca.ca_city,
      ca.ca_state,
      c.c_last_review_date,
      ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_last_review_date DESC) AS rn
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_location_type = 'apartment'
      AND c.c_last_review_date >= 2452360
  ),
  base_condos AS (
    SELECT
      c.c_customer_id,
      c.c_last_name,
      ca.ca_city,
      ca.ca_state,
      c.c_last_review_date,
      ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_last_review_date DESC) AS rn
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_location_type = 'condo'
      AND c.c_last_review_date >= 2452360
  ),
  union_set AS (
    SELECT c_customer_id, c_last_name, ca_city, ca_state, c_last_review_date, rn FROM base_apartments
    UNION
    SELECT c_customer_id, c_last_name, ca_city, ca_state, c_last_review_date, rn FROM base_condos
  ),
  state_ca_single_family AS (
    SELECT DISTINCT c.c_customer_id
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND ca.ca_location_type = 'single family'
  ),
  state_ny_apartments AS (
    SELECT DISTINCT c.c_customer_id
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'NY'
      AND ca.ca_location_type = 'apartment'
  ),
  filtered_ids AS (
    SELECT c_customer_id
    FROM (
      SELECT c_customer_id FROM union_set
      INTERSECT
      SELECT c_customer_id FROM state_ca_single_family
    ) AS intersected
    EXCEPT
    SELECT c_customer_id FROM state_ny_apartments
  )
SELECT
  u.c_customer_id,
  u.c_last_name,
  u.ca_city,
  u.ca_state,
  u.c_last_review_date,
  u.rn
FROM union_set u
JOIN filtered_ids f
  ON u.c_customer_id = f.c_customer_id
WHERE NOT EXISTS (
        SELECT 1
        FROM tpcds.customer c2
        JOIN tpcds.customer_address ca2
          ON c2.c_current_addr_sk = ca2.ca_address_sk
        WHERE c2.c_customer_id = u.c_customer_id
          AND ca2.ca_location_type = 'single family'
          AND ca2.ca_state = 'TX'
      )
ORDER BY u.c_last_review_date DESC, u.rn
LIMIT 100
