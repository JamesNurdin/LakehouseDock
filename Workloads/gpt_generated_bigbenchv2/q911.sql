WITH filtered_pages AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_length
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
    AVG(name_length) AS avg_name_length
FROM filtered_pages
GROUP BY w_web_page_type
ORDER BY page_count DESC
LIMIT 10
