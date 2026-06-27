WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_len,
        MIN(LENGTH(w_web_page_name)) AS min_name_len,
        MAX(LENGTH(w_web_page_name)) AS max_name_len
    FROM web_pages
    GROUP BY w_web_page_type
    HAVING COUNT(*) > 5
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    min_name_len,
    max_name_len,
    RANK() OVER (ORDER BY page_count DESC) AS type_rank_by_page_count
FROM page_stats
ORDER BY page_count DESC
