SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ds.d_year AS store_closed_year,
    ds.d_month_seq AS store_closed_month_seq,
    da.d_year AS access_year,
    da.d_quarter_name AS access_quarter,
    COUNT(*) AS total_pages,
    SUM(wp.wp_image_count) AS total_images,
    SUM(wp.wp_link_count) AS total_links,
    AVG(wp.wp_char_count) AS avg_char_count,
    SUM(CASE WHEN da.d_weekend = 'Y' THEN wp.wp_image_count ELSE 0 END) AS weekend_images,
    SUM(CASE WHEN da.d_weekend <> 'Y' THEN wp.wp_image_count ELSE 0 END) AS weekday_images,
    COUNT(DISTINCT wp.wp_type) AS distinct_page_types,
    SUM(CASE WHEN wp.wp_type = 'product' THEN 1 ELSE 0 END) AS product_page_count,
    SUM(CASE WHEN wp.wp_type = 'category' THEN 1 ELSE 0 END) AS category_page_count,
    SUM(COALESCE(wp.wp_max_ad_count, 0)) AS total_max_ads,
    CASE
        WHEN COUNT(*) = 0 THEN 0
        ELSE CAST(SUM(wp.wp_image_count) AS double) / COUNT(*)
    END AS avg_images_per_page
FROM store s
JOIN date_dim ds
    ON s.s_closed_date_sk = ds.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = ds.d_date_sk
JOIN date_dim da
    ON wp.wp_access_date_sk = da.d_date_sk
WHERE s.s_closed_date_sk IS NOT NULL
  AND wp.wp_creation_date_sk IS NOT NULL
  AND wp.wp_access_date_sk IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ds.d_year,
    ds.d_month_seq,
    da.d_year,
    da.d_quarter_name,
    da.d_weekend
HAVING COUNT(*) > 10
ORDER BY total_pages DESC
LIMIT 100
