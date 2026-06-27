WITH page_metrics AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        substring(w_web_page_name, 1, 1) AS first_char
    FROM web_pages
)
SELECT
    w_web_page_type,
    first_char,
    COUNT(*) AS page_cnt,
    AVG(name_len) AS avg_name_len,
    MAX(name_len) AS longest_name_len,
    MIN(name_len) AS shortest_name_len
FROM page_metrics
GROUP BY w_web_page_type, first_char
ORDER BY page_cnt DESC, w_web_page_type, first_char
