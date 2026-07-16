WITH filtered_customers AS (
    SELECT c_customer_sk,
           c_birth_year,
           c_preferred_cust_flag,
           c_birth_day,
           c_last_review_date
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
      AND c_birth_day IN (7, 9, 18)
      AND c_last_review_date > 2452300
),
page_stats AS (
    SELECT wp_customer_sk,
           wp_type,
           COUNT(*) AS page_cnt,
           SUM(wp_char_count) AS total_chars,
           AVG(wp_image_count) AS avg_images,
           MAX(wp_link_count) AS max_links
    FROM web_page
    WHERE wp_type IS NOT NULL
    GROUP BY wp_customer_sk, wp_type
),
joined AS (
    SELECT fc.c_birth_year AS birth_year,
           ps.wp_type,
           ps.page_cnt,
           ps.total_chars,
           ps.avg_images,
           ps.max_links
    FROM filtered_customers fc
    JOIN page_stats ps ON fc.c_customer_sk = ps.wp_customer_sk
)
SELECT birth_year,
       wp_type,
       page_cnt,
       total_chars,
       avg_images,
       max_links,
       RANK() OVER (PARTITION BY birth_year ORDER BY total_chars DESC) AS type_rank,
       (SELECT r_reason_desc FROM reason WHERE r_reason_id = 'R001' LIMIT 1) AS reason_desc
FROM joined
WHERE page_cnt >= 5
ORDER BY birth_year, type_rank
LIMIT 100
