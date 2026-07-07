WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        MAX(length(w_web_page_name)) AS max_name_length
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    max_name_length
FROM page_stats
ORDER BY page_count DESC
