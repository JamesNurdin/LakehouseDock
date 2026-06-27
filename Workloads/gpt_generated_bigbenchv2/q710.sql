WITH page_stats AS (
    SELECT
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_len,
        w_web_page_id
    FROM web_pages
),
type_agg AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_cnt,
        AVG(name_len) AS avg_name_len,
        MAX(name_len) AS max_name_len,
        MIN(name_len) AS min_name_len
    FROM page_stats
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_cnt,
    avg_name_len,
    max_name_len,
    min_name_len,
    CAST(page_cnt * 100.0 / SUM(page_cnt) OVER () AS double) AS pct_of_total_pages
FROM type_agg
ORDER BY page_cnt DESC
