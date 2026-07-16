WITH customer_web_stats AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    ca.ca_country,
    ca.ca_state,
    ca.ca_city,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_pages,
    SUM(wp.wp_image_count) AS total_images,
    SUM(wp.wp_link_count) AS total_links,
    SUM(wp.wp_char_count) AS total_chars
  FROM customer c
  JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
  WHERE c.c_birth_month IN (4, 7, 9, 10)
    AND c.c_last_review_date >= 2452390
    AND wp.wp_type = 'PRODUCT'
  GROUP BY
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    ca.ca_country,
    ca.ca_state,
    ca.ca_city
)
SELECT
  ca_country,
  ca_state,
  COUNT(*) AS num_customers,
  SUM(num_pages) AS total_pages,
  SUM(total_images) AS total_images,
  SUM(total_links) AS total_links,
  AVG(total_chars) AS avg_chars_per_customer,
  RANK() OVER (ORDER BY SUM(total_chars) DESC) AS global_char_rank,
  ROW_NUMBER() OVER (PARTITION BY ca_country ORDER BY SUM(total_chars) DESC) AS country_customer_rank
FROM customer_web_stats
GROUP BY ca_country, ca_state
HAVING COUNT(*) >= 3
   AND SUM(total_images) > 0
ORDER BY global_char_rank
LIMIT 50
