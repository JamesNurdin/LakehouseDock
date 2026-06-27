WITH page_lengths AS (
    SELECT
        w_web_page_type,
        w_web_page_id,
        LENGTH(w_web_page_name) AS name_len
    FROM web_pages
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    COUNT(DISTINCT w_web_page_id) AS distinct_page_ids,
    MAX(w_web_page_id) AS max_page_id,
    MIN(w_web_page_id) AS min_page_id,
    AVG(name_len) AS avg_name_length,
    APPROX_PERCENTILE(name_len, 0.5) AS median_name_length
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY page_count DESC
