WITH page_stats AS (
    SELECT
        wp.wp_type,
        d1.d_fy_year AS creation_fy_year,
        COUNT(*) AS page_cnt,
        SUM(wp.wp_image_count) AS img_cnt,
        AVG(wp.wp_char_count) AS avg_char_cnt
    FROM date_dim d1
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d1.d_date_sk
    INNER JOIN date_dim d2
        ON wp.wp_access_date_sk = d2.d_date_sk
    WHERE d1.d_fy_year = 1904                                   -- filter 1
      AND d2.d_qoy IN (1, 2)                                    -- filter 2
      AND wp.wp_image_count >= 3                               -- filter 3
      AND wp.wp_type IS NOT NULL                               -- filter 4
    GROUP BY ROLLUP (wp.wp_type, d1.d_fy_year)
)
SELECT
    wp_type,
    creation_fy_year,
    page_cnt,
    img_cnt,
    avg_char_cnt,
    RANK() OVER (PARTITION BY creation_fy_year ORDER BY page_cnt DESC) AS rank_within_year,
    CASE
        WHEN creation_fy_year IS NULL THEN 'Subtotal Year'
        WHEN wp_type IS NULL THEN 'Subtotal Type'
        ELSE 'Detail'
    END AS row_category
FROM page_stats
ORDER BY
    creation_fy_year ASC NULLS LAST,
    wp_type ASC NULLS LAST,
    rank_within_year
LIMIT 100
