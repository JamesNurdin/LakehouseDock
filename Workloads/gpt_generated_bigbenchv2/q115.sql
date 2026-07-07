WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(length(w_web_page_name)) AS avg_name_len
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len
FROM page_stats
ORDER BY page_count DESC
