WITH agg AS (
    SELECT
        cp.cp_department AS department,
        ws.web_country AS country,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS num_pages,
        SUM(wp.wp_image_count) AS total_images,
        AVG(wp.wp_char_count) AS avg_char_count,
        MAX(cp.cp_end_date_sk) AS latest_end_sk
    FROM catalog_page cp
    JOIN web_page wp
        ON cp.cp_start_date_sk = wp.wp_creation_date_sk
    JOIN web_site ws
        ON wp.wp_access_date_sk = ws.web_close_date_sk
    WHERE cp.cp_end_date_sk BETWEEN 2450900 AND 2451200
      AND wp.wp_image_count > 0
      AND ws.web_state = 'CA'
    GROUP BY cp.cp_department, ws.web_country
    HAVING COUNT(DISTINCT cp.cp_catalog_page_id) >= 5
)
SELECT
    department,
    country,
    num_pages,
    total_images,
    avg_char_count,
    latest_end_sk,
    RANK() OVER (ORDER BY total_images DESC) AS image_rank
FROM agg
ORDER BY total_images DESC
LIMIT 50
