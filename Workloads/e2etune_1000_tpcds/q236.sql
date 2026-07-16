WITH wp_stats AS (
    SELECT 
        wp_web_page_id,
        COUNT(*) AS page_count,
        SUM(wp_char_count) AS total_chars,
        AVG(wp_image_count) AS avg_images
    FROM web_page
    WHERE wp_type = 'PRODUCT'
    GROUP BY wp_web_page_id
),
store_ship AS (
    SELECT 
        s.s_store_id,
        s.s_state,
        s.s_floor_space,
        s.s_gmt_offset,
        sm.sm_type,
        sm.sm_carrier
    FROM store s
    JOIN ship_mode sm ON s.s_store_sk = sm.sm_ship_mode_sk
    WHERE s.s_rec_end_date IS NULL
),
agg AS (
    SELECT 
        ss.s_state,
        ss.sm_type,
        COUNT(DISTINCT ss.s_store_id) AS store_cnt,
        SUM(ss.s_floor_space) AS total_floor_space,
        AVG(ss.s_gmt_offset) AS avg_gmt_offset,
        SUM(COALESCE(ws.page_count, 0)) AS total_page_count,
        SUM(COALESCE(ws.total_chars, 0)) AS total_chars
    FROM store_ship ss
    LEFT JOIN wp_stats ws ON ss.s_store_id = ws.wp_web_page_id
    WHERE ss.sm_carrier IN ('UPS', 'FEDEX')
    GROUP BY ss.s_state, ss.sm_type
    HAVING COUNT(DISTINCT ss.s_store_id) >= 5
)
SELECT 
    a.s_state,
    a.sm_type,
    a.store_cnt,
    a.total_floor_space,
    a.avg_gmt_offset,
    a.total_page_count,
    a.total_chars,
    RANK() OVER (PARTITION BY a.s_state ORDER BY a.total_floor_space DESC) AS floor_space_rank
FROM agg a
ORDER BY a.s_state, floor_space_rank
LIMIT 100
