WITH page_name_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    MIN(name_len) AS min_name_len,
    MAX(name_len) AS max_name_len,
    AVG(name_len) AS avg_name_len
FROM page_name_lengths
GROUP BY w_web_page_type
ORDER BY page_count DESC
