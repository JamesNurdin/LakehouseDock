WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_length
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    MIN(name_length) AS min_name_length,
    MAX(name_length) AS max_name_length,
    AVG(name_length) AS avg_name_length,
    STDDEV_POP(name_length) AS name_length_stddev
FROM page_lengths
GROUP BY w_web_page_type
HAVING COUNT(*) > 5
ORDER BY page_count DESC
