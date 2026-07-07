WITH page_stats AS (
    SELECT
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        w_web_page_id
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(name_len) AS avg_name_length,
    MIN(w_web_page_id) AS min_page_id,
    MAX(w_web_page_id) AS max_page_id
FROM page_stats
GROUP BY w_web_page_type
ORDER BY page_count DESC
