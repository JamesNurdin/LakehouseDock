WITH filtered AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        wp.wp_image_count,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_max_ad_count
    FROM tpcds.customer c
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_image_count >= 2
      AND wp.wp_char_count > 500
      AND c.c_salutation IN ('Mr.', 'Mrs.')
),
agg AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        COUNT(DISTINCT wp_image_count) AS distinct_image_counts,
        SUM(wp_image_count) AS total_image_count,
        AVG(wp_char_count) AS avg_char_count,
        MIN(wp_link_count) AS min_link_count,
        MAX(wp_max_ad_count) AS max_ad_count
    FROM filtered
    GROUP BY c_customer_id, c_first_name, c_last_name
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    distinct_image_counts,
    total_image_count,
    avg_char_count,
    min_link_count,
    max_ad_count,
    RANK() OVER (ORDER BY total_image_count DESC) AS image_count_rank
FROM agg
ORDER BY image_count_rank
LIMIT 100
