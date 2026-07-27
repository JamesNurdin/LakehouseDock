SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       wp.wp_url,
       wp.wp_type
FROM tpcds.customer AS c
JOIN tpcds.web_page AS wp
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_salutation = 'Mrs.'
  AND wp.wp_type = 'welcome'
ORDER BY c.c_customer_id
LIMIT 100
