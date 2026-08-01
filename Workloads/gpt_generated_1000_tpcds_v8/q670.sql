SELECT
  wp.wp_type,
  COUNT(DISTINCT c.c_customer_sk) AS distinct_customer_count
FROM tpcds.customer c
JOIN tpcds.web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE wp.wp_rec_end_date = DATE '2000-09-02'
  AND c.c_birth_year > 1970
GROUP BY wp.wp_type
ORDER BY distinct_customer_count DESC
LIMIT 5
