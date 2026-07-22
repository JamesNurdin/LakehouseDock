SELECT DISTINCT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       wp.wp_url
FROM tpcds.customer c
JOIN tpcds.web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_current_hdemo_sk IN (3062, 4505)
  AND wp.wp_char_count > 2000
ORDER BY c.c_customer_id
LIMIT 100
