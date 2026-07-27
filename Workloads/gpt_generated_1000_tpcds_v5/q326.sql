WITH preferred_customers AS (
    SELECT c_customer_sk, c_customer_id, c_first_name, c_last_name
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
)
SELECT pc.c_customer_id,
       pc.c_first_name,
       pc.c_last_name,
       wp.wp_url,
       wp.wp_type,
       wp.wp_image_count
FROM preferred_customers pc
JOIN web_page wp
  ON wp.wp_customer_sk = pc.c_customer_sk
WHERE wp.wp_image_count > 3
  AND wp.wp_rec_end_date >= DATE '2000-01-01'
UNION ALL
SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       wp.wp_url,
       wp.wp_type,
       wp.wp_image_count
FROM customer c
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'N'
  AND wp.wp_image_count <= 4
  AND wp.wp_rec_end_date < DATE '2000-01-01'
LIMIT 100
