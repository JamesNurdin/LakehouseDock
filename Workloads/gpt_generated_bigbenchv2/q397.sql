WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    pl.w_web_page_type,
    COUNT(DISTINCT pl.w_web_page_id) AS page_count,
    AVG(pl.name_len) AS avg_name_length
FROM page_lengths pl
GROUP BY pl.w_web_page_type
ORDER BY page_count DESC
LIMIT 10
