SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    MAX(length(w_web_page_name)) AS max_name_length,
    MIN(length(w_web_page_name)) AS min_name_length
FROM web_pages
WHERE w_web_page_type IS NOT NULL
  AND w_web_page_name IS NOT NULL
GROUP BY w_web_page_type
ORDER BY page_count DESC
