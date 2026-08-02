SELECT c.c_customer_id,
       c.c_last_name,
       c.c_email_address,
       wp.wp_url,
       wp.wp_char_count
FROM tpcds.customer AS c
JOIN tpcds.web_page AS wp
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE wp.wp_char_count > 3000
  AND c.c_last_name = 'White'
LIMIT 100
