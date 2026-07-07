WITH page_aggregates AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
        MAX(w_web_page_id) AS max_page_id
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    max_page_id
FROM page_aggregates
ORDER BY page_count DESC
