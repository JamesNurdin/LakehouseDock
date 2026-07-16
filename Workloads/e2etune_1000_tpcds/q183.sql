WITH filtered_customers AS (
    SELECT c_customer_sk,
           c_birth_country
    FROM customer
    WHERE c_birth_country IN ('IRELAND', 'CYPRUS', 'VANUATU')
      AND c_first_sales_date_sk >= 2452000
),
page_stats AS (
    SELECT wp.wp_customer_sk,
           wp.wp_type,
           COUNT(*) AS page_count,
           AVG(wp.wp_char_count) AS avg_char_count,
           SUM(wp.wp_image_count) AS total_image_count,
           SUM(wp.wp_link_count) AS total_link_count
    FROM web_page wp
    GROUP BY wp.wp_customer_sk, wp.wp_type
),
joined_stats AS (
    SELECT fc.c_birth_country,
           ps.wp_type,
           COUNT(DISTINCT fc.c_customer_sk) AS num_customers,
           SUM(ps.page_count) AS total_pages,
           AVG(ps.avg_char_count) AS avg_char_per_page,
           SUM(ps.total_image_count) AS total_images,
           SUM(ps.total_link_count) AS total_links
    FROM filtered_customers fc
    JOIN page_stats ps
      ON fc.c_customer_sk = ps.wp_customer_sk
    GROUP BY fc.c_birth_country, ps.wp_type
    HAVING SUM(ps.page_count) > 2
)
SELECT
    c_birth_country,
    wp_type,
    num_customers,
    total_pages,
    avg_char_per_page,
    total_images,
    total_links,
    ROW_NUMBER() OVER (PARTITION BY c_birth_country ORDER BY avg_char_per_page DESC) AS rank_by_char,
    (SELECT COUNT(*) FROM reason) AS total_reason_count,
    (SELECT t_meal_time FROM time_dim WHERE t_hour = 12 LIMIT 1) AS midday_meal_time
FROM joined_stats
ORDER BY c_birth_country, rank_by_char
LIMIT 50
