WITH type_counts AS (
    SELECT w_web_page_type,
           COUNT(*) AS page_count
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT w_web_page_type,
       page_count
FROM type_counts
WHERE page_count > 0
ORDER BY page_count DESC
