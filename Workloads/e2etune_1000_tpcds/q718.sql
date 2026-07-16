WITH wp_agg AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_image_count,
        wp.wp_url,
        substr(wp.wp_url, 1, 1) AS url_prefix
    FROM web_page wp
    WHERE wp.wp_rec_start_date >= DATE '2022-01-01'
),
state_stats AS (
    SELECT
        w.w_state,
        COUNT(DISTINCT wp.wp_web_page_id) AS page_count,
        AVG(wp.wp_image_count) AS avg_image_count,
        SUM(w.w_warehouse_sq_ft) AS total_sq_ft
    FROM warehouse w
    JOIN wp_agg wp
      ON substr(w.w_zip, 1, 1) = wp.url_prefix
    WHERE w.w_country = 'United States'
      AND w.w_warehouse_sq_ft > 0
    GROUP BY w.w_state
    HAVING COUNT(DISTINCT wp.wp_web_page_id) >= 10
)
SELECT
    s.w_state,
    s.page_count,
    s.avg_image_count,
    s.total_sq_ft,
    RANK() OVER (ORDER BY s.page_count DESC) AS state_rank
FROM state_stats s
ORDER BY s.page_count DESC
LIMIT 20
