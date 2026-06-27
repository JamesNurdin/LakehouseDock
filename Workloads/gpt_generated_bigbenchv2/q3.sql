WITH page_lengths AS (
    SELECT
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        w_web_page_id
    FROM web_pages
    WHERE w_web_page_name IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS total_pages,
    COUNT(DISTINCT w_web_page_id) AS distinct_page_ids,
    AVG(name_len) AS avg_name_len,
    MIN(name_len) AS min_name_len,
    MAX(name_len) AS max_name_len
FROM page_lengths
GROUP BY w_web_page_type
HAVING COUNT(*) > 5
ORDER BY total_pages DESC
