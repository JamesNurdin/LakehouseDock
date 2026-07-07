WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_name IS NOT NULL
)
SELECT
    w_web_page_type,
    name_len,
    COUNT(*) AS page_count
FROM page_lengths
GROUP BY w_web_page_type, name_len
ORDER BY page_count DESC
LIMIT 20
