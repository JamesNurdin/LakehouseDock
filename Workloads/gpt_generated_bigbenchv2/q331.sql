WITH filtered_pages AS (
    SELECT w_web_page_name, w_web_page_type
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT w_web_page_type,
       COUNT(*) AS page_count
FROM filtered_pages
GROUP BY w_web_page_type
ORDER BY page_count DESC
LIMIT 10
