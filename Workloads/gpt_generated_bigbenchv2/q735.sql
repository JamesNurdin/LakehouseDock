WITH page_stats AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        CASE
            WHEN length(w_web_page_name) <= 10 THEN 'short'
            WHEN length(w_web_page_name) <= 20 THEN 'medium'
            ELSE 'long'
        END AS name_len_category
    FROM web_pages
)
SELECT
    w_web_page_type,
    name_len_category,
    COUNT(*) AS page_count,
    AVG(name_len) AS avg_name_len,
    MIN(name_len) AS min_name_len,
    MAX(name_len) AS max_name_len
FROM page_stats
GROUP BY w_web_page_type, name_len_category
ORDER BY w_web_page_type, page_count DESC
