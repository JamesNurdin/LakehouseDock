WITH hd_stats AS (
    SELECT
        1 AS dummy_key,
        hd_income_band_sk,
        COUNT(*) AS hd_cnt,
        AVG(hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(CASE WHEN hd_buy_potential = '>10000' THEN 1 ELSE 0 END) AS high_potential_cnt
    FROM household_demographics
    WHERE hd_income_band_sk BETWEEN 2 AND 5
      AND hd_dep_count >= 1
    GROUP BY hd_income_band_sk
),
wh_stats AS (
    SELECT
        1 AS dummy_key,
        w_state,
        COUNT(*) AS wh_cnt,
        SUM(w_warehouse_sq_ft) AS total_sq_ft,
        AVG(w_warehouse_sq_ft) AS avg_sq_ft
    FROM warehouse
    WHERE w_city IN ('Shiloh', 'Fairview', 'Riverside')
      AND w_gmt_offset BETWEEN -5.00 AND 5.00
    GROUP BY w_state
),
wp_stats AS (
    SELECT
        1 AS dummy_key,
        wp_type,
        COUNT(*) AS wp_cnt,
        AVG(wp_char_count) AS avg_char_cnt,
        AVG(wp_image_count) AS avg_image_cnt
    FROM web_page
    WHERE wp_rec_start_date >= DATE '2023-01-01'
      AND wp_autogen_flag = 'N'
    GROUP BY wp_type
)
SELECT
    hd.hd_income_band_sk,
    hd.avg_vehicle_cnt,
    hd.high_potential_cnt,
    wh.w_state,
    wh.total_sq_ft,
    wp.wp_type,
    wp.avg_char_cnt,
    (hd.avg_vehicle_cnt * wh.total_sq_ft) AS vehicle_sqft_score,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY (hd.avg_vehicle_cnt * wh.total_sq_ft) DESC) AS rank_within_income_band
FROM hd_stats hd
JOIN wh_stats wh ON hd.dummy_key = wh.dummy_key
JOIN wp_stats wp ON hd.dummy_key = wp.dummy_key
WHERE hd.high_potential_cnt > 0
ORDER BY hd.hd_income_band_sk, rank_within_income_band
LIMIT 50
