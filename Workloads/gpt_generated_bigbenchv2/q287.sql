WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_type,
        w_web_page_name,
        LENGTH(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(name_len) AS avg_name_length,
    MIN(w_web_page_id) AS min_page_id
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY COUNT(*) DESC
LIMIT 5
