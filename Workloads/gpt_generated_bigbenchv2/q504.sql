SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(LENGTH(w_web_page_name)) AS avg_name_length,
    MAX(LENGTH(w_web_page_name)) AS max_name_length
FROM web_pages
WHERE w_web_page_type IS NOT NULL
GROUP BY w_web_page_type
ORDER BY page_count DESC
LIMIT 10
