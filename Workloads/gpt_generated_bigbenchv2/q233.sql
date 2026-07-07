SELECT w_web_page_type,
       COUNT(*) AS page_count,
       COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
       MIN(w_web_page_id) AS min_page_id,
       MAX(w_web_page_id) AS max_page_id
FROM web_pages
WHERE w_web_page_type IS NOT NULL
GROUP BY w_web_page_type
ORDER BY page_count DESC
LIMIT 10
