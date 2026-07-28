SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    w.wp_url,
    w.wp_char_count
FROM tpcds.customer c
JOIN tpcds.web_page w
  ON w.wp_customer_sk = c.c_customer_sk
WHERE c.c_birth_day = 26
  AND w.wp_char_count > 3000
LIMIT 100
