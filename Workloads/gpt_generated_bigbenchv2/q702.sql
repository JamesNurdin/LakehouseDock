WITH type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
        MAX(LENGTH(w_web_page_name)) AS max_name_length,
        approx_percentile(LENGTH(w_web_page_name), 0.5) AS median_name_length
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    max_name_length,
    median_name_length,
    RANK() OVER (ORDER BY page_count DESC) AS rank_by_page_count
FROM type_stats
ORDER BY rank_by_page_count
