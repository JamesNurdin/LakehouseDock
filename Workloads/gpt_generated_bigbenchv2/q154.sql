WITH page_type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS total_pages,
        COUNT(DISTINCT w_web_page_id) AS distinct_page_ids,
        AVG(LENGTH(w_web_page_name)) AS avg_name_length
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    total_pages,
    distinct_page_ids,
    avg_name_length
FROM page_type_stats
ORDER BY total_pages DESC
