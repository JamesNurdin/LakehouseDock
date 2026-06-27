WITH type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS total_pages,
        COUNT(DISTINCT w_web_page_name) AS distinct_page_names,
        AVG(length(w_web_page_name)) AS avg_name_length
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    total_pages,
    distinct_page_names,
    avg_name_length,
    rank() OVER (ORDER BY total_pages DESC) AS type_rank_by_page_count
FROM type_stats
ORDER BY type_rank_by_page_count
