SELECT w_web_page_type,
       COUNT(*) AS page_count,
       AVG(LENGTH(w_web_page_name)) AS avg_name_length
FROM web_pages
GROUP BY w_web_page_type
ORDER BY page_count DESC
LIMIT 10
