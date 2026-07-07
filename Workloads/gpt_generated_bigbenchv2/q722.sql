WITH page_counts AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
        MAX(LENGTH(w_web_page_name)) AS max_name_length
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
    HAVING COUNT(*) > 10
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    max_name_length
FROM page_counts
ORDER BY page_count DESC
