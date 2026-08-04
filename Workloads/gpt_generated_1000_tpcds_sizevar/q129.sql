WITH filtered AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_rec_end_date,
        c.c_customer_id,
        c.c_birth_day,
        c.c_birth_month,
        c.c_preferred_cust_flag
    FROM web_page wp
    RIGHT OUTER JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_rec_end_date >= DATE '2000-01-01'
      AND wp.wp_char_count BETWEEN 1200 AND 2500
      AND c.c_birth_month = 5
      AND c.c_preferred_cust_flag = 'Y'
        -- additional realistic predicate
      AND wp.wp_link_count > 5
)
SELECT
    wp_web_page_id,
    COUNT(DISTINCT c_customer_id) AS distinct_customer_cnt,
    AVG(wp_char_count) AS avg_char_count,
    MAX(wp_link_count) AS max_link_count,
    MIN(wp_char_count) AS min_char_count
FROM filtered
GROUP BY wp_web_page_id
ORDER BY distinct_customer_cnt DESC, avg_char_count DESC
LIMIT 100
