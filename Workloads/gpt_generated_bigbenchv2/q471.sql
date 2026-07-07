SELECT w_web_page_type, COUNT(*) AS page_count
FROM web_pages
WHERE w_web_page_name IS NOT NULL
GROUP BY w_web_page_type
ORDER BY page_count DESC
