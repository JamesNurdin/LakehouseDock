WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_len,
        MIN(w_web_page_id) AS min_page_id,
        MAX(w_web_page_id) AS max_page_id
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    avg_name_len,
    min_page_id,
    max_page_id,
    RANK() OVER (ORDER BY page_count DESC) AS page_count_rank
FROM page_stats
ORDER BY page_count DESC
