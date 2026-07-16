SELECT
    s.s_store_id,
    CONCAT(CAST(d_closure.d_year AS VARCHAR), '-', d_closure.d_quarter_name) AS closure_quarter,
    d_access.d_quarter_name AS access_quarter,
    COUNT(DISTINCT wp.wp_web_page_id) AS unique_pages,
    SUM(wp.wp_char_count) AS total_characters,
    AVG(wp.wp_image_count) AS avg_image_count,
    SUM(CASE WHEN d_access.d_weekend = 'Y' THEN 1 ELSE 0 END) AS weekend_accesses,
    COUNT(*) FILTER (WHERE wp.wp_autogen_flag = 'Y') AS auto_generated_pages,
    ROUND(AVG(wp.wp_char_count), 2) AS avg_chars_per_page
FROM store s
JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_closure.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE s.s_state = 'CA'
  AND d_closure.d_year = 2023
  AND wp.wp_type = 'product'
GROUP BY
    s.s_store_id,
    CONCAT(CAST(d_closure.d_year AS VARCHAR), '-', d_closure.d_quarter_name),
    d_access.d_quarter_name
HAVING COUNT(DISTINCT wp.wp_web_page_id) > 5
ORDER BY total_characters DESC
LIMIT 100
