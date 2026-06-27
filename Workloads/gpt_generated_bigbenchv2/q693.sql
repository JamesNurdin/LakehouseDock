WITH page_type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
        COUNT(DISTINCT w_web_page_name) * 1.0 / COUNT(*) AS distinct_ratio,
        AVG(LENGTH(w_web_page_name)) AS avg_name_length
    FROM web_pages
    GROUP BY w_web_page_type
    HAVING COUNT(*) > 5
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    distinct_ratio,
    avg_name_length,
    RANK() OVER (ORDER BY page_count DESC) AS type_rank
FROM page_type_stats
ORDER BY type_rank
