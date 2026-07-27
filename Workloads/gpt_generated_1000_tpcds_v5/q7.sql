SELECT c.c_email_address,
       c.c_birth_day,
       w.wp_url,
       w.wp_image_count
FROM tpcds.customer AS c
JOIN tpcds.web_page AS w
  ON w.wp_customer_sk = c.c_customer_sk
WHERE w.wp_rec_end_date = DATE '2000-09-02'
  AND c.c_birth_day = 15
  AND w.wp_image_count > 4
LIMIT 100
