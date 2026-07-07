WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_length
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    avg_name_length
FROM page_stats
ORDER BY page_count DESC
