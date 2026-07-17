SELECT c.c_birth_country AS birth_country,
       wp.wp_type AS page_type,
       COUNT(*) AS page_count,
       AVG(wp.wp_image_count) AS avg_image_count
FROM web_page wp
JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
WHERE wp.wp_autogen_flag = 'N'
  AND wp.wp_image_count >= 4
  AND c.c_birth_country IN ('BAHAMAS', 'MOZAMBIQUE', 'VANUATU')
  AND wp.wp_rec_start_date >= DATE '2023-01-01'
  AND wp.wp_rec_end_date <= DATE '2023-12-31'
GROUP BY c.c_birth_country, wp.wp_type
HAVING COUNT(*) >= 10
ORDER BY avg_image_count DESC
