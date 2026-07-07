WITH page_metrics AS (
    SELECT
        w_web_page_type,
        w_web_page_name,
        length(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_name IS NOT NULL
      AND w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(name_len) AS avg_name_length,
    MAX(name_len) AS max_name_length
FROM page_metrics
GROUP BY w_web_page_type
ORDER BY page_count DESC
