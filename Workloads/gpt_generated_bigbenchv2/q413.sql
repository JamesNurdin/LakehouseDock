SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    approx_distinct(w_web_page_id) AS distinct_pages,
    avg(length(w_web_page_name)) AS avg_name_length,
    max(length(w_web_page_name)) AS max_name_length,
    max_by(w_web_page_name, length(w_web_page_name)) AS longest_page_name
FROM web_pages
GROUP BY w_web_page_type
ORDER BY page_count DESC
