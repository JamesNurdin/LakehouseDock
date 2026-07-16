WITH cc_agg AS (
    SELECT
        cc.cc_mkt_class,
        cc.cc_manager,
        SUM(cc.cc_employees) AS total_employees,
        AVG(cc.cc_tax_percentage) AS avg_tax,
        COUNT(*) AS num_centers
    FROM call_center cc
    WHERE cc.cc_country = 'United States'
      AND cc.cc_tax_percentage > 0
      AND cc.cc_mkt_id IN (2, 3, 4, 5, 6)
      AND cc.cc_rec_start_date >= DATE '2015-01-01'
    GROUP BY cc.cc_mkt_class, cc.cc_manager
    HAVING COUNT(*) >= 2
),
wp_agg AS (
    SELECT
        wp.wp_type,
        SUM(wp.wp_link_count) AS total_links,
        AVG(wp.wp_image_count) AS avg_images
    FROM web_page wp
    WHERE wp.wp_image_count > 0
    GROUP BY wp.wp_type
)
SELECT
    cc_agg.cc_mkt_class,
    cc_agg.cc_manager,
    cc_agg.total_employees,
    cc_agg.avg_tax,
    cc_agg.num_centers,
    wp_agg.wp_type,
    wp_agg.total_links,
    wp_agg.avg_images,
    RANK() OVER (ORDER BY cc_agg.total_employees DESC) AS employee_rank
FROM cc_agg
JOIN wp_agg ON true
ORDER BY cc_agg.total_employees DESC
LIMIT 50
