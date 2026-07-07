SELECT w_web_page_type,
       COUNT(*) AS page_count,
       COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
       MAX(length(w_web_page_name)) AS max_name_length,
       MIN(length(w_web_page_name)) AS min_name_length,
       AVG(length(w_web_page_name)) AS avg_name_length
FROM web_pages
GROUP BY w_web_page_type
ORDER BY page_count DESC
