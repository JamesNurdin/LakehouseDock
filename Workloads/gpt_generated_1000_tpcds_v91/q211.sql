SELECT c.c_customer_id,
       c.c_email_address,
       wp.wp_url,
       wp.wp_char_count,
       wp.wp_max_ad_count
FROM web_page wp
JOIN customer c
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_email_address LIKE '%@aKRz.edu'
  AND wp.wp_char_count >= 1500
ORDER BY wp.wp_char_count DESC
