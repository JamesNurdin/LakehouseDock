WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_len,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY LENGTH(w_web_page_name) DESC) AS rn
    FROM web_pages
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(name_len) AS avg_name_length,
    APPROX_PERCENTILE(name_len, 0.5) AS median_name_length,
    MAX(name_len) AS max_name_length,
    MIN(name_len) AS min_name_length,
    ARRAY_AGG(w_web_page_name ORDER BY name_len DESC) FILTER (WHERE rn <= 3) AS top_3_longest_pages
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY page_count DESC
