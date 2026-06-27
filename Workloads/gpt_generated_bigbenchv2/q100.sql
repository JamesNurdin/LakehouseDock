WITH type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_len,
        MAX(LENGTH(w_web_page_name)) AS max_name_len,
        ARRAY_AGG(w_web_page_name ORDER BY LENGTH(w_web_page_name) DESC)[1] AS longest_page_name
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    max_name_len,
    longest_page_name
FROM type_stats
ORDER BY page_count DESC
