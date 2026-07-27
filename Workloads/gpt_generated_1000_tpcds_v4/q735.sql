WITH cp_agg AS (
    SELECT
        cp_department,
        cp_type,
        COUNT(*) AS page_cnt,
        AVG(cp_catalog_number) AS avg_catalog_num,
        MIN(cp_start_date_sk) AS min_start_sk
    FROM catalog_page
    WHERE cp_type IN ('quarterly', 'monthly')
    GROUP BY cp_department, cp_type
)
SELECT
    cp_agg.cp_department,
    cp_agg.cp_type,
    cp_agg.page_cnt,
    cp_agg.avg_catalog_num,
    ws.web_name,
    ws.web_state,
    wp.wp_url,
    start_d.d_year AS start_year,
    end_d.d_year AS end_year,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
    SUM(COALESCE(wp.wp_image_count, 0)) AS total_images
FROM cp_agg
JOIN catalog_page cp
    ON cp.cp_department = cp_agg.cp_department
   AND cp.cp_type = cp_agg.cp_type
JOIN date_dim start_d
    ON cp.cp_start_date_sk = start_d.d_date_sk
JOIN date_dim end_d
    ON cp.cp_end_date_sk = end_d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = start_d.d_date_sk
JOIN date_dim wp_access_d
    ON wp.wp_access_date_sk = wp_access_d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = start_d.d_date_sk
JOIN date_dim ws_close_d
    ON ws.web_close_date_sk = ws_close_d.d_date_sk
WHERE
    start_d.d_year = 2001
    AND end_d.d_year = 2001
    AND ws.web_state = 'CA'
    AND ws.web_zip = '88054'
    AND wp.wp_type = 'home'
    AND start_d.d_dow = 5
    AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = wp.wp_customer_sk
          AND wp2.wp_image_count > 10
    )
GROUP BY
    cp_agg.cp_department,
    cp_agg.cp_type,
    cp_agg.page_cnt,
    cp_agg.avg_catalog_num,
    ws.web_name,
    ws.web_state,
    wp.wp_url,
    start_d.d_year,
    end_d.d_year
ORDER BY total_images DESC
LIMIT 100
