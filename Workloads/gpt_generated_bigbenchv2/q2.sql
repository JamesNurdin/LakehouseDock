WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_length
    FROM web_pages
)
SELECT
    pl.w_web_page_type,
    COUNT(*) AS page_count,
    AVG(pl.name_length) AS avg_name_length,
    MIN(pl.w_web_page_id) AS min_page_id,
    MAX(pl.w_web_page_id) AS max_page_id
FROM page_lengths AS pl
GROUP BY pl.w_web_page_type
ORDER BY page_count DESC
