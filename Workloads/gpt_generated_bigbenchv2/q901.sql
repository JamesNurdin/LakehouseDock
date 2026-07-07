WITH page_counts AS (
    SELECT 
        w_web_page_type,
        COUNT(*) AS total_pages,
        COUNT(DISTINCT w_web_page_name) AS distinct_names
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT 
    w_web_page_type,
    total_pages,
    distinct_names,
    ROUND(total_pages * 100.0 / SUM(total_pages) OVER (), 2) AS pct_of_total
FROM page_counts
ORDER BY total_pages DESC
LIMIT 10
