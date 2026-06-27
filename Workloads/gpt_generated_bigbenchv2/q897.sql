WITH type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_length
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_length,
    page_count * 100.0 / SUM(page_count) OVER () AS pct_of_total_pages
FROM type_stats
ORDER BY page_count DESC
