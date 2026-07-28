WITH wp_agg AS (
    SELECT wp_customer_sk,
           COUNT(*) AS page_cnt,
           SUM(wp_image_count) AS total_images,
           AVG(wp_char_count) AS avg_char_cnt
    FROM web_page
    WHERE wp_autogen_flag = 'N'
      AND wp_image_count >= 3
    GROUP BY wp_customer_sk
),
addr_filter AS (
    SELECT ca_address_sk,
           ca_state,
           ca_city,
           ca_suite_number
    FROM customer_address
    WHERE ca_state IN ('CA', 'TX')
      AND ca_suite_number LIKE 'Suite %'
)
SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       a.ca_state,
       a.ca_city,
       a.ca_suite_number,
       w.page_cnt,
       w.total_images,
       w.avg_char_cnt,
       w.total_images / NULLIF(w.page_cnt, 0) AS images_per_page,
       (SELECT MAX(wp_image_count) FROM web_page) AS max_image_count_overall
FROM wp_agg w
JOIN customer c ON w.wp_customer_sk = c.c_customer_sk
JOIN addr_filter a ON c.c_current_addr_sk = a.ca_address_sk
WHERE c.c_birth_year BETWEEN 1960 AND 1980
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_link_count > 5
    )
ORDER BY w.total_images DESC
LIMIT 100
