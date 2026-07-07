WITH page_lengths AS (
    SELECT
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
)
SELECT
    pl.w_web_page_type,
    COUNT(*) AS page_count,
    AVG(pl.name_len) AS avg_name_length
FROM page_lengths pl
GROUP BY pl.w_web_page_type
ORDER BY page_count DESC
LIMIT 10
