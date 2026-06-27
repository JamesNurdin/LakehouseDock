WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_len
    FROM web_pages
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    COUNT(DISTINCT w_web_page_id) AS distinct_page_ids,
    MAX(name_len) AS max_name_length,
    MIN(name_len) AS min_name_length,
    AVG(name_len) AS avg_name_length
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY page_count DESC
