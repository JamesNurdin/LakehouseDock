WITH page_stats AS (
    SELECT
        c.c_birth_month,
        wp.wp_type,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
        SUM(wp.wp_char_count) AS total_char_count,
        AVG(wp.wp_char_count) AS avg_char_count,
        SUM(wp.wp_image_count) AS total_image_count,
        SUM(wp.wp_link_count) AS total_link_count
    FROM web_page wp
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month IN (4, 12)
      AND wp.wp_type IS NOT NULL
    GROUP BY c.c_birth_month, wp.wp_type
    HAVING COUNT(*) > 5
)
SELECT
    c_birth_month,
    wp_type,
    page_cnt,
    total_char_count,
    avg_char_count,
    total_image_count,
    total_link_count,
    RANK() OVER (PARTITION BY c_birth_month ORDER BY total_char_count DESC) AS char_count_rank
FROM page_stats
ORDER BY c_birth_month, char_count_rank
