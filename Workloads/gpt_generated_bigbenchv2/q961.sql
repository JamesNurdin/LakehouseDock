SELECT
   w_web_page_type,
   count(*) AS page_count,
   avg(length(w_web_page_name)) AS avg_name_length,
   min(length(w_web_page_name)) AS min_name_length,
   max(length(w_web_page_name)) AS max_name_length
FROM web_pages
GROUP BY w_web_page_type
ORDER BY page_count DESC
