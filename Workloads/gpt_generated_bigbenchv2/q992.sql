WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
        MAX(length(w_web_page_name)) AS max_name_length,
        MIN(length(w_web_page_name)) AS min_name_length
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    max_name_length,
    min_name_length
FROM page_stats
ORDER BY page_count DESC
