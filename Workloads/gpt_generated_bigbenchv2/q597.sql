WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS total_pages,
        COUNT(DISTINCT w_web_page_id) AS distinct_ids,
        AVG(LENGTH(w_web_page_name)) AS avg_name_len,
        MIN(LENGTH(w_web_page_name)) AS min_name_len,
        MAX(LENGTH(w_web_page_name)) AS max_name_len,
        approx_percentile(LENGTH(w_web_page_name), 0.5) AS median_name_len
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    total_pages,
    distinct_ids,
    avg_name_len,
    min_name_len,
    max_name_len,
    median_name_len,
    RANK() OVER (ORDER BY total_pages DESC) AS type_rank_by_pages
FROM page_stats
ORDER BY total_pages DESC
