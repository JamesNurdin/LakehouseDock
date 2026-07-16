WITH aggregated AS (
    SELECT
        ws.web_site_id,
        ws.web_city,
        sm.sm_carrier,
        ib.ib_income_band_sk,
        COUNT(DISTINCT wp.wp_web_page_sk) AS num_pages,
        SUM(wp.wp_image_count) AS total_images,
        AVG(wp.wp_char_count) AS avg_char_count,
        SUM(wp.wp_link_count) AS total_links
    FROM web_page wp
    JOIN income_band ib
      ON wp.wp_char_count BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    JOIN ship_mode sm
      ON sm.sm_ship_mode_sk = ib.ib_income_band_sk
    JOIN web_site ws
      ON sm.sm_ship_mode_id = ws.web_site_id
    WHERE wp.wp_type = 'HTML'
      AND ws.web_state = 'CA'
      AND sm.sm_carrier IN ('UPS', 'FEDEX')
    GROUP BY
        ws.web_site_id,
        ws.web_city,
        sm.sm_carrier,
        ib.ib_income_band_sk
    HAVING COUNT(DISTINCT wp.wp_web_page_sk) > 5
)
SELECT
    a.*,
    RANK() OVER (PARTITION BY a.web_city ORDER BY a.total_images DESC) AS city_image_rank,
    ROW_NUMBER() OVER (PARTITION BY a.sm_carrier ORDER BY a.avg_char_count DESC) AS carrier_char_rank
FROM aggregated a
ORDER BY a.total_images DESC
LIMIT 100
