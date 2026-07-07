WITH page_counts AS (
    SELECT w_web_page_type, COUNT(*) AS page_count
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT w_web_page_type, page_count
FROM page_counts
ORDER BY page_count DESC
