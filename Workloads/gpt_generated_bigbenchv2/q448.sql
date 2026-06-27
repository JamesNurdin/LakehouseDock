WITH page_stats AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        COUNT(*) OVER (PARTITION BY w_web_page_type) AS page_count,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY w_web_page_id DESC) AS rn
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    page_stats.w_web_page_type,
    page_stats.page_count,
    page_stats.w_web_page_id,
    page_stats.w_web_page_name
FROM page_stats
WHERE page_stats.rn = 1
ORDER BY page_stats.page_count DESC
LIMIT 5
