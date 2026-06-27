SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
    AVG(length(w_web_page_name)) AS avg_name_length,
    MAX(length(w_web_page_name)) AS max_name_length
FROM web_pages
WHERE w_web_page_type IS NOT NULL
GROUP BY w_web_page_type
HAVING COUNT(*) > 5
ORDER BY page_count DESC
