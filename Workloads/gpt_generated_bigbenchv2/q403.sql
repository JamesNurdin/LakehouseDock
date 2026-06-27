WITH page_stats AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        length(w_web_page_name) AS name_length,
        w_web_page_type
    FROM web_pages
    WHERE w_web_page_name IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(name_length) AS avg_name_length,
    MAX(name_length) AS max_name_length,
    MIN(name_length) AS min_name_length
FROM page_stats
GROUP BY w_web_page_type
ORDER BY page_count DESC
