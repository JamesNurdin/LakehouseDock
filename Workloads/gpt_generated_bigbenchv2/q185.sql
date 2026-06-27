WITH type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS cnt,
        COUNT(DISTINCT w_web_page_id) AS distinct_ids,
        AVG(LENGTH(w_web_page_name)) AS avg_name_len
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    cnt,
    distinct_ids,
    avg_name_len,
    ROW_NUMBER() OVER (ORDER BY cnt DESC) AS rank_by_cnt,
    ROUND(cnt * 100.0 / SUM(cnt) OVER (), 2) AS pct_of_total
FROM type_stats
WHERE cnt > 5
ORDER BY cnt DESC
