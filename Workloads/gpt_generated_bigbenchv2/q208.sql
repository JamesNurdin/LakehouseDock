WITH page_counts AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_length
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    avg_name_length,
    page_count * 1.0 / SUM(page_count) OVER () AS proportion_of_total_pages,
    ROW_NUMBER() OVER (ORDER BY page_count DESC) AS type_rank
FROM page_counts
ORDER BY page_count DESC
