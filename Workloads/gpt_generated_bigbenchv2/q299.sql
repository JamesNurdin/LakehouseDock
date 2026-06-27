WITH page_stats AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        substr(w_web_page_name, 1, 1) AS first_char
    FROM web_pages
)
SELECT
    w_web_page_type,
    first_char,
    COUNT(*) AS page_count,
    AVG(name_len) AS avg_name_len,
    MAX(name_len) AS max_name_len
FROM page_stats
GROUP BY w_web_page_type, first_char
ORDER BY page_count DESC
LIMIT 20
