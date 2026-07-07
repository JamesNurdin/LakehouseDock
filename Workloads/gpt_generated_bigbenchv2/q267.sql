WITH page_counts AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_id) AS distinct_id_count,
        MIN(w_web_page_id) AS min_id,
        MAX(w_web_page_id) AS max_id
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_id_count,
    min_id,
    max_id
FROM page_counts
ORDER BY page_count DESC
