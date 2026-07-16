SELECT
    city,
    state,
    wp_type,
    warehouse_cnt,
    avg_warehouse_size,
    total_image_count,
    avg_char_count,
    latest_creation_sk,
    page_cnt,
    ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_image_count DESC) AS city_type_rank
FROM (
    SELECT
        w.w_city AS city,
        w.w_state AS state,
        wp.wp_type AS wp_type,
        COUNT(DISTINCT w.w_warehouse_id) AS warehouse_cnt,
        AVG(w.w_warehouse_sq_ft) AS avg_warehouse_size,
        SUM(wp.wp_image_count) AS total_image_count,
        AVG(wp.wp_char_count) AS avg_char_count,
        MAX(wp.wp_creation_date_sk) AS latest_creation_sk,
        COUNT(wp.wp_web_page_id) AS page_cnt
    FROM
        warehouse w
        CROSS JOIN web_page wp
    WHERE
        w.w_gmt_offset = -5.00
        AND w.w_warehouse_sq_ft BETWEEN 300000 AND 900000
        AND wp.wp_type IN ('Home', 'Product', 'Search')
    GROUP BY
        w.w_city,
        w.w_state,
        wp.wp_type
    HAVING
        COUNT(DISTINCT w.w_warehouse_id) >= 1
        AND COUNT(wp.wp_web_page_id) > 10
) t
ORDER BY
    total_image_count DESC
LIMIT 200
