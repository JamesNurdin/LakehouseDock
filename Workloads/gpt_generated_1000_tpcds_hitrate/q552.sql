WITH filtered_customers AS (
  SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    c_email_address,
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    CASE 
      WHEN REGEXP_LIKE(c_email_address, '^.*@.*\\.com$') THEN 'COM'
      WHEN REGEXP_LIKE(c_email_address, '^.*@.*\\.org$') THEN 'ORG'
      ELSE 'OTHER'
    END AS email_domain_type
  FROM customer
  WHERE c_birth_country LIKE 'A%'
    AND REGEXP_LIKE(c_email_address, '@')
),

email_parts AS (
  SELECT
    fc.c_customer_sk,
    part AS email_part,
    fc.email_domain_type
  FROM filtered_customers fc
  CROSS JOIN UNNEST(split(fc.c_email_address, '@')) AS t(part)
),

sales_sample AS (
  SELECT *
  FROM store_sales
  TABLESAMPLE BERNOULLI (5)
  WHERE ss_net_paid > 0
)
SELECT
  COALESCE(s.s_store_name, 'ALL_STORES') AS store_name,
  COALESCE(ca.ca_city, 'ALL_CITIES') AS city,
  CASE
    WHEN GROUPING(s.s_store_name) = 0 AND GROUPING(ca.ca_city) = 1 THEN 'BY_STORE'
    WHEN GROUPING(s.s_store_name) = 1 AND GROUPING(ca.ca_city) = 0 THEN 'BY_CITY'
    ELSE 'TOTAL'
  END AS grouping_level,
  SUM(ss.ss_net_paid) AS total_net_paid,
  COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
  COUNT(DISTINCT ep.email_part) AS distinct_email_parts,
  SUM(CASE WHEN ss.ss_quantity > 5 THEN ss.ss_ext_sales_price ELSE 0 END) AS large_qty_sales
FROM sales_sample ss
JOIN filtered_customers fc ON ss.ss_customer_sk = fc.c_customer_sk
JOIN email_parts ep ON ep.c_customer_sk = fc.c_customer_sk
LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
GROUP BY GROUPING SETS ((s.s_store_name), (ca.ca_city), ())
ORDER BY total_net_paid DESC
LIMIT 100
