WITH page_type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_cnt,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_cnt,
        AVG(LENGTH(w_web_page_name)) AS avg_name_len,
        MIN(LENGTH(w_web_page_name)) AS min_name_len,
        MAX(LENGTH(w_web_page_name)) AS max_name_len
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_cnt,
    distinct_name_cnt,
    avg_name_len,
    min_name_len,
    max_name_len,
    RANK() OVER (ORDER BY page_cnt DESC) AS type_rank_by_page_cnt
FROM page_type_stats
ORDER BY page_cnt DESC
