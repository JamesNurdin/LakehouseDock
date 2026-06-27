SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total_pages,
    MAX(LENGTH(w_web_page_name)) AS max_name_length,
    AVG(LENGTH(w_web_page_name)) AS avg_name_length
FROM web_pages
GROUP BY w_web_page_type
ORDER BY page_count DESC
