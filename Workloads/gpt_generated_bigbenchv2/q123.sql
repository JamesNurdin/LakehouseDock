WITH type_counts AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS type_page_count
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    type_page_count,
    ROUND(100.0 * type_page_count / SUM(type_page_count) OVER (), 2) AS pct_of_total_pages
FROM type_counts
ORDER BY type_page_count DESC
