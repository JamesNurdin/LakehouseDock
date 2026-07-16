SELECT
  c.c_birth_year,
  wp.wp_type,
  COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
  SUM(wp.wp_image_count) AS total_images,
  AVG(wp.wp_char_count) AS avg_char_len,
  RANK() OVER (PARTITION BY c.c_birth_year ORDER BY SUM(wp.wp_image_count) DESC) AS img_rank,
  (SELECT COUNT(*) FROM item WHERE i_units = 'Each') AS total_each_items,
  (SELECT AVG(i_current_price) FROM item WHERE i_category = 'Sports') AS avg_price_sports,
  (SELECT MAX(cp_catalog_page_number) FROM catalog_page WHERE cp_department = 'Sports') AS max_catalog_page_num_sports
FROM web_page wp
JOIN customer c
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE wp.wp_image_count > 2
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY c.c_birth_year, wp.wp_type
HAVING COUNT(DISTINCT wp.wp_web_page_sk) >= 5
ORDER BY total_images DESC, page_cnt ASC
LIMIT 100
