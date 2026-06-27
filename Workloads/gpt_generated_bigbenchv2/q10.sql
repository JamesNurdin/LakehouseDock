WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_cnt,
        AVG(length(w_web_page_name)) AS avg_name_len,
        MIN(length(w_web_page_name)) AS min_name_len,
        MAX(length(w_web_page_name)) AS max_name_len
    FROM web_pages
    GROUP BY w_web_page_type
    HAVING COUNT(*) > 5
)
SELECT
    w_web_page_type,
    page_cnt,
    avg_name_len,
    min_name_len,
    max_name_len,
    RANK() OVER (ORDER BY page_cnt DESC) AS type_rank
FROM page_stats
ORDER BY type_rank
