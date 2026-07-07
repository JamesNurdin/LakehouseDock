WITH page_counts AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_cnt,
        COUNT(DISTINCT w_web_page_id) AS distinct_page_cnt
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_cnt,
    distinct_page_cnt
FROM page_counts
ORDER BY page_cnt DESC
LIMIT 10
