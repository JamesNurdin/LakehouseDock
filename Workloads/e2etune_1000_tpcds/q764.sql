WITH filtered_customers AS (
  SELECT c.*, ca.ca_state, ca.ca_city
  FROM customer c
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE c.c_birth_year BETWEEN 1970 AND 2000
    AND c.c_preferred_cust_flag IS NOT NULL
    AND c.c_current_addr_sk IN (2282946, 3681655, 4748572)
),
city_agg AS (
  SELECT
    ca_state,
    ca_city,
    COUNT(*) AS num_customers,
    AVG(c_birth_year) AS avg_birth_year,
    SUM(CASE WHEN c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS pref_cust_ratio,
    COUNT(DISTINCT SPLIT_PART(c_email_address, '@', 2)) AS distinct_email_domains
  FROM filtered_customers
  GROUP BY ca_state, ca_city
  HAVING COUNT(*) >= 3
)
SELECT
  ca_state,
  ca_city,
  num_customers,
  avg_birth_year,
  pref_cust_ratio,
  distinct_email_domains,
  RANK() OVER (PARTITION BY ca_state ORDER BY num_customers DESC) AS city_rank_in_state
FROM city_agg
ORDER BY ca_state, city_rank_in_state
LIMIT 100
