WITH site_ad_stats AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        COUNT(DISTINCT wp.wp_web_page_id) AS page_cnt,
        AVG(wp.wp_max_ad_count) AS avg_max_ad_cnt,
        SUM(wp.wp_max_ad_count) AS total_max_ad_cnt,
        MAX(wp.wp_rec_start_date) AS latest_page_date
    FROM web_page wp
    JOIN web_site ws
        ON wp.wp_creation_date_sk = ws.web_open_date_sk
    WHERE wp.wp_type = 'ad'
      AND wp.wp_rec_start_date >= DATE '2000-01-01'
      AND ws.web_state = 'CA'
    GROUP BY ws.web_site_id, ws.web_name
)
SELECT
    web_site_id,
    web_name,
    page_cnt,
    avg_max_ad_cnt,
    total_max_ad_cnt,
    latest_page_date,
    RANK() OVER (ORDER BY avg_max_ad_cnt DESC) AS avg_ad_rank
FROM site_ad_stats
WHERE page_cnt >= 5
ORDER BY avg_max_ad_cnt DESC
LIMIT 20
