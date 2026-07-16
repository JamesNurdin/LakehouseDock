SELECT
    s.s_division_name,
    d_start.d_year,
    d_start.d_quarter_name,
    CASE WHEN d_start.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    cp.cp_type,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS catalog_page_cnt,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_page_cnt,
    SUM(wp.wp_image_count) AS total_image_count,
    AVG(wp.wp_char_count) AS avg_char_count,
    MIN(d_access.d_date) AS earliest_access_date,
    MAX(d_end.d_date) AS latest_end_date
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    s.s_division_name,
    d_start.d_year,
    d_start.d_quarter_name,
    CASE WHEN d_start.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    cp.cp_type
HAVING COUNT(DISTINCT cp.cp_catalog_page_id) > 5
ORDER BY total_image_count DESC
LIMIT 100
