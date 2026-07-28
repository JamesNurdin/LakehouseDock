SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    w.wp_url,
    w.wp_char_count
FROM tpcds.customer c
JOIN tpcds.web_page w
  ON w.wp_customer_sk = c.c_customer_sk
WHERE w.wp_rec_start_date = DATE '2000-09-03'
  AND c.c_birth_country = 'UKRAINE'
  AND w.wp_char_count > 1500
ORDER BY w.wp_char_count DESC
LIMIT 100
