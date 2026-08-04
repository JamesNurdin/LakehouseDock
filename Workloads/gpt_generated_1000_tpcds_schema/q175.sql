WITH intersected_customers AS (
  SELECT c_customer_sk FROM (
    SELECT DISTINCT wp.wp_customer_sk AS c_customer_sk
    FROM web_page wp TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*\\.example\\.com/.*')
      AND wp.wp_type LIKE 'content%'
  )
  INTERSECT
  SELECT c_customer_sk FROM (
    SELECT DISTINCT c.c_customer_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(c.c_email_address, '@(gmail|yahoo)\\.com$')
      AND hd.hd_vehicle_count > 0
      AND hd.hd_dep_count >= 2
  )
)
SELECT
  c.c_customer_sk,
  c.c_first_name,
  c.c_last_name,
  COUNT(DISTINCT wp.wp_web_page_sk) AS page_count,
  MIN(d.d_date) AS first_page_date,
  CONCAT('Customer_', CAST(c.c_customer_sk AS varchar)) AS customer_key,
  array_agg(DISTINCT regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)) AS domains
FROM intersected_customers ic
JOIN customer c ON ic.c_customer_sk = c.c_customer_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
WHERE wp.wp_url LIKE '%example.com%'
GROUP BY
  c.c_customer_sk,
  c.c_first_name,
  c.c_last_name,
  CONCAT('Customer_', CAST(c.c_customer_sk AS varchar))
ORDER BY page_count DESC, first_page_date ASC
LIMIT 100
