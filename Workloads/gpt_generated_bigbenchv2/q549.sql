SELECT
    wp.w_web_page_type,
    COUNT(*) AS page_count,
    COUNT(DISTINCT wp.w_web_page_name) AS distinct_name_count
FROM web_pages wp
WHERE wp.w_web_page_type IS NOT NULL
GROUP BY wp.w_web_page_type
ORDER BY page_count DESC
LIMIT 10
