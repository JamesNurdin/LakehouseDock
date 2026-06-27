WITH page_type_summary AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
        MIN(w_web_page_id) AS min_page_id,
        MAX(w_web_page_id) AS max_page_id,
        APPROX_PERCENTILE(CAST(w_web_page_id AS DOUBLE), 0.5) AS median_page_id
    FROM web_pages
    GROUP BY w_web_page_type
    HAVING COUNT(*) > 10
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    min_page_id,
    max_page_id,
    median_page_id
FROM page_type_summary
ORDER BY page_count DESC
