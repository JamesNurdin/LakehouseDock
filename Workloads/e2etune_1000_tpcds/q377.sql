WITH filtered_pages AS (
  SELECT
    wp_customer_sk,
    SUM(wp_link_count) AS total_links,
    COUNT(*) AS page_count,
    AVG(wp_image_count) AS avg_images,
    approx_percentile(wp_char_count, 0.5) AS median_char_count
  FROM web_page
  WHERE wp_access_date_sk BETWEEN 2451000 AND 2452000
    AND wp_type = 'article'
  GROUP BY wp_customer_sk
)
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  c.c_email_address,
  c.c_birth_year,
  fp.page_count,
  fp.total_links,
  fp.avg_images,
  fp.median_char_count,
  RANK() OVER (ORDER BY fp.total_links DESC) AS link_rank
FROM customer c
JOIN filtered_pages fp ON c.c_customer_sk = fp.wp_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_month IN (3, 4, 5)
ORDER BY fp.total_links DESC
LIMIT 15
