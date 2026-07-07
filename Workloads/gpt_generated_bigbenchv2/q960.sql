WITH page_stats AS (
    SELECT
        w_web_page_type,
        avg(length(w_web_page_name)) AS avg_name_len,
        count(*) AS page_count
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    page_stats.w_web_page_type,
    page_stats.avg_name_len,
    page_stats.page_count
FROM page_stats
ORDER BY page_stats.page_count DESC
