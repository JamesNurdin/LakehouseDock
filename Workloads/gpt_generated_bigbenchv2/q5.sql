WITH type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_len,
        approx_percentile(LENGTH(w_web_page_name), 0.5) AS median_name_len,
        MIN(w_web_page_id) AS min_page_id,
        MAX(w_web_page_id) AS max_page_id
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    median_name_len,
    min_page_id,
    max_page_id,
    ROW_NUMBER() OVER (ORDER BY page_count DESC) AS type_rank
FROM type_stats
ORDER BY page_count DESC
