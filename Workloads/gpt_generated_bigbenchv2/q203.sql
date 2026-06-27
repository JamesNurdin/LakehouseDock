WITH page_type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    ROUND(100.0 * page_count / SUM(page_count) OVER (), 2) AS pct_of_total_pages
FROM page_type_stats
ORDER BY page_count DESC
