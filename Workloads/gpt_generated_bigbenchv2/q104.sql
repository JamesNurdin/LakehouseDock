WITH page_stats AS (
    SELECT
        w_web_page_type,
        w_web_page_name,
        LENGTH(w_web_page_name) AS name_len
    FROM web_pages
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
    AVG(name_len) AS avg_name_length,
    MAX(name_len) AS max_name_length,
    MIN(name_len) AS min_name_length
FROM page_stats
GROUP BY w_web_page_type
ORDER BY page_count DESC
