SELECT
    d.d_year,
    d.d_month_seq,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter_bucket,
    s.s_state,
    ws.web_state,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT s.s_store_sk) AS distinct_stores,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
    SUM(wp.wp_image_count) AS total_images,
    SUM(wp.wp_link_count) AS total_links,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    MAX(ws.web_tax_percentage) AS max_site_tax,
    SUM(CASE WHEN wp.wp_autogen_flag = 'Y' THEN 1 ELSE 0 END) AS autogen_pages,
    COUNT(*) FILTER (WHERE d.d_holiday = 'Y') AS holiday_rows,
    COUNT(*) FILTER (WHERE wp.wp_type = 'blog') AS blog_pages,
    (SUM(wp.wp_image_count) * 1.0) / NULLIF(COUNT(DISTINCT wp.wp_web_page_sk), 0) AS avg_images_per_page
FROM date_dim d
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2010 AND 2020
  AND ws.web_close_date_sk > ws.web_open_date_sk
GROUP BY
    d.d_year,
    d.d_month_seq,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    s.s_state,
    ws.web_state
HAVING COUNT(*) > 100
ORDER BY d.d_year DESC, d.d_month_seq DESC
LIMIT 100
