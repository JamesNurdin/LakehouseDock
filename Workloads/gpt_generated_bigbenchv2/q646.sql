SELECT
    w_web_page_type,
    COUNT(DISTINCT w_web_page_id) AS distinct_page_count,
    AVG(LENGTH(w_web_page_name)) AS avg_name_length
FROM web_pages
GROUP BY w_web_page_type
ORDER BY distinct_page_count DESC
LIMIT 10
