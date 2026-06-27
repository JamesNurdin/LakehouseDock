WITH total_counts AS (
    SELECT COUNT(*) AS total_pages
    FROM web_pages
),
type_counts AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS type_page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
        MAX(LENGTH(w_web_page_name)) AS max_name_length,
        MIN(LENGTH(w_web_page_name)) AS min_name_length,
        AVG(LENGTH(w_web_page_name)) AS avg_name_length
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    tc.w_web_page_type,
    tc.type_page_count,
    tc.distinct_name_count,
    tc.max_name_length,
    tc.min_name_length,
    ROUND(tc.avg_name_length, 2) AS avg_name_length,
    ROUND(100.0 * tc.type_page_count / t.total_pages, 2) AS pct_of_total_pages
FROM type_counts tc
CROSS JOIN total_counts t
ORDER BY tc.type_page_count DESC
