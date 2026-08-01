SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  COUNT(wp.wp_web_page_sk) AS page_count
FROM
  customer c
JOIN
  web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE
  c.c_birth_country = 'SWITZERLAND'
  AND wp.wp_autogen_flag = 'Y'
  AND wp.wp_type = 'ad'
GROUP BY
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name
ORDER BY
  page_count DESC
LIMIT 100
