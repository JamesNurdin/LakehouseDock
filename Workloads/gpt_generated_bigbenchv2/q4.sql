/* Analytical query: statistics per web page type, including name‑length metrics */
WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
)
SELECT
    w_web_page_type,
    COUNT(*) AS total_pages,
    COUNT(DISTINCT w_web_page_id) AS distinct_pages,
    MAX(name_len) AS max_name_len,
    MIN(name_len) AS min_name_len,
    AVG(name_len) AS avg_name_len
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY total_pages DESC
