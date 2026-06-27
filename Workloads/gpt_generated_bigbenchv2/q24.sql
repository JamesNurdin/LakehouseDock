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
    COUNT(*) AS total_pages,
    AVG(name_len) AS avg_name_len,
    MIN(name_len) AS min_name_len,
    MAX(name_len) AS max_name_len,
    COUNT(DISTINCT w_web_page_id) AS distinct_pages
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY total_pages DESC
