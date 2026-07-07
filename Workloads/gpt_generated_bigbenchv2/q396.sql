WITH page_counts AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count
    FROM web_pages
    WHERE w_web_page_name IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count
FROM page_counts
ORDER BY page_count DESC
