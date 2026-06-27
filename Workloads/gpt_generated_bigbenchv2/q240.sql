WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_cnt,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_cnt,
        MIN(w_web_page_id) AS min_page_id,
        MAX(w_web_page_id) AS max_page_id
    FROM web_pages
    GROUP BY w_web_page_type
    HAVING COUNT(*) > 5
)
SELECT
    w_web_page_type,
    page_cnt,
    distinct_name_cnt,
    (page_cnt - distinct_name_cnt) AS duplicate_name_cnt,
    min_page_id,
    max_page_id,
    ROW_NUMBER() OVER (ORDER BY page_cnt DESC) AS rank_by_page_cnt
FROM page_stats
ORDER BY page_cnt DESC
