SELECT
    w.w_web_page_type,
    COUNT(*) AS page_count,
    AVG(LENGTH(w.w_web_page_name)) AS avg_name_length,
    MAX(LENGTH(w.w_web_page_name)) AS max_name_length
FROM web_pages AS w
WHERE w.w_web_page_type IS NOT NULL
GROUP BY w.w_web_page_type
ORDER BY page_count DESC
