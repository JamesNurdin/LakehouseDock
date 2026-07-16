WITH address_state_agg AS (
    SELECT
        ca_state,
        COUNT(*) AS address_cnt,
        AVG(ca_gmt_offset) AS avg_gmt_offset,
        MIN(ca_gmt_offset) AS min_gmt_offset,
        MAX(ca_gmt_offset) AS max_gmt_offset
    FROM customer_address
    WHERE ca_country = 'United States'
    GROUP BY ca_state
),
 demo_income_agg AS (
    SELECT
        hd_income_band_sk,
        AVG(hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(hd_dep_count) AS total_dep_cnt,
        COUNT(*) AS demo_cnt
    FROM household_demographics
    GROUP BY hd_income_band_sk
),
 web_page_agg AS (
    SELECT
        wp_type,
        COUNT(*) AS page_cnt,
        AVG(wp_char_count) AS avg_char_cnt,
        approx_percentile(wp_image_count, 0.5) AS median_image_cnt,
        MAX(wp_link_count) AS max_link_cnt
    FROM web_page
    WHERE wp_rec_start_date >= DATE '2020-01-01'
    GROUP BY wp_type
)
SELECT
    a.ca_state,
    d.hd_income_band_sk,
    w.wp_type,
    a.address_cnt,
    d.demo_cnt,
    w.page_cnt,
    a.avg_gmt_offset,
    d.avg_vehicle_cnt,
    w.avg_char_cnt,
    w.median_image_cnt,
    ROW_NUMBER() OVER (PARTITION BY a.ca_state ORDER BY d.avg_vehicle_cnt DESC) AS rn_state
FROM address_state_agg a
JOIN demo_income_agg d ON a.address_cnt = d.demo_cnt
JOIN web_page_agg w ON a.address_cnt = w.page_cnt
WHERE a.avg_gmt_offset > -7.00
  AND d.total_dep_cnt > 0
ORDER BY a.ca_state, rn_state
LIMIT 100
