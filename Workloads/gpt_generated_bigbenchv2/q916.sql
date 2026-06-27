WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(length(w_web_page_name)) AS avg_name_len,
        MAX(length(w_web_page_name)) AS max_name_len,
        MIN(length(w_web_page_name)) AS min_name_len
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    ps.w_web_page_type,
    ps.page_count,
    ps.avg_name_len,
    ps.max_name_len,
    ps.min_name_len,
    ps.page_count * 1.0 / total.total_pages AS pct_of_total_pages
FROM page_stats ps
CROSS JOIN (
    SELECT COUNT(*) AS total_pages FROM web_pages
) total
ORDER BY ps.page_count DESC
