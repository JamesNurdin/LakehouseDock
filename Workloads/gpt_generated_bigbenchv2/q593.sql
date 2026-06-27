WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(length(w_web_page_name)) AS avg_name_length,
        MAX(length(w_web_page_name)) AS max_name_length,
        MIN(length(w_web_page_name)) AS min_name_length
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_length,
    max_name_length,
    min_name_length,
    ROW_NUMBER() OVER (ORDER BY page_count DESC) AS type_rank,
    SUM(page_count) OVER (ORDER BY page_count DESC) AS cumulative_page_count
FROM page_stats
ORDER BY page_count DESC
