WITH page_metrics AS (
    SELECT
        s.s_store_id,
        ws.web_site_id,
        d_store.d_date AS store_closed_date,
        d_site_close.d_date AS site_close_date,
        COUNT(*) AS num_pages,
        SUM(wp.wp_image_count) AS total_images,
        SUM(wp.wp_link_count) AS total_links,
        AVG(wp.wp_char_count) AS avg_char_count,
        AVG(DATE_DIFF('day', d_store.d_date, d_page_access.d_date)) AS avg_days_to_access,
        MIN(DATE_DIFF('day', d_store.d_date, d_page_access.d_date)) AS min_days_to_access,
        MAX(DATE_DIFF('day', d_store.d_date, d_page_access.d_date)) AS max_days_to_access,
        SUM(CASE WHEN wp.wp_type = 'article' THEN wp.wp_image_count ELSE 0 END) AS article_images,
        SUM(CASE WHEN wp.wp_type = 'advertisement' THEN wp.wp_image_count ELSE 0 END) AS ad_images,
        s.s_gmt_offset AS store_gmt_offset,
        ws.web_gmt_offset AS site_gmt_offset,
        s.s_tax_percentage AS store_tax_pct,
        ws.web_tax_percentage AS site_tax_pct
    FROM store s
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_store.d_date_sk
    JOIN date_dim d_site_close ON ws.web_close_date_sk = d_site_close.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_store.d_date_sk
    JOIN date_dim d_page_access ON wp.wp_access_date_sk = d_page_access.d_date_sk
    WHERE s.s_state = 'CA' AND ws.web_state = 'CA'
    GROUP BY
        s.s_store_id,
        ws.web_site_id,
        d_store.d_date,
        d_site_close.d_date,
        s.s_gmt_offset,
        ws.web_gmt_offset,
        s.s_tax_percentage,
        ws.web_tax_percentage
)
SELECT
    pm.s_store_id,
    pm.web_site_id,
    pm.store_closed_date,
    pm.site_close_date,
    pm.num_pages,
    pm.total_images,
    ROUND(pm.total_images * 1.0 / NULLIF(pm.total_links, 0), 2) AS images_per_link,
    pm.avg_days_to_access,
    CASE
        WHEN pm.avg_days_to_access <= 7 THEN 'FastAccess'
        WHEN pm.avg_days_to_access <= 30 THEN 'ModerateAccess'
        ELSE 'SlowAccess'
    END AS access_speed_category,
    pm.article_images,
    pm.ad_images,
    pm.store_gmt_offset,
    pm.site_gmt_offset,
    pm.store_tax_pct,
    pm.site_tax_pct,
    ROW_NUMBER() OVER (PARTITION BY pm.s_store_id ORDER BY pm.total_images DESC) AS store_image_rank
FROM page_metrics pm
WHERE pm.num_pages > 10
ORDER BY pm.total_images DESC
LIMIT 100
