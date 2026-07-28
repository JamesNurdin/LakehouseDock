WITH filtered AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_image_count,
        c.c_last_review_date
    FROM web_page wp
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_web_page_id IN ('AAAAAAAAPBAAAAAA','AAAAAAAAKBAAAAAA')
      AND wp.wp_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
      AND wp.wp_char_count > 3000
      AND c.c_birth_year BETWEEN 1950 AND 1970
)
SELECT
    wp_web_page_id,
    COUNT(*) AS page_views,
    SUM(wp_char_count) AS total_chars,
    AVG(wp_link_count) AS avg_links,
    MIN(wp_image_count) AS min_images,
    MAX(c_last_review_date) AS latest_review_date
FROM filtered
GROUP BY wp_web_page_id
ORDER BY total_chars DESC
LIMIT 100
