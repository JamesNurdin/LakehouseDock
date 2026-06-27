WITH page_name_stats AS (
    SELECT
        w_web_page_id,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS total_pages,
    COUNT(DISTINCT w_web_page_id) AS unique_pages,
    MAX(name_len) AS max_name_length,
    MIN(name_len) AS min_name_length,
    AVG(name_len) AS avg_name_length,
    APPROX_PERCENTILE(name_len, 0.5) AS median_name_length
FROM page_name_stats
GROUP BY w_web_page_type
ORDER BY total_pages DESC
