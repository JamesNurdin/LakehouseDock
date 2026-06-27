WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    count(*) AS page_count,
    count(DISTINCT w_web_page_name) AS distinct_name_count,
    avg(name_len) AS avg_name_len,
    approx_percentile(name_len, 0.5) AS median_name_len,
    max(name_len) AS max_name_len
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY page_count DESC
