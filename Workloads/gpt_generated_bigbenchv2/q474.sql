WITH page_lengths AS (
    SELECT
        w_web_page_type,
        w_web_page_id,
        length(w_web_page_name) AS name_length
    FROM web_pages
)
SELECT
    page_lengths.w_web_page_type,
    count(*) AS page_count,
    avg(page_lengths.w_web_page_id) AS avg_page_id,
    max(page_lengths.name_length) AS max_name_length,
    min(page_lengths.name_length) AS min_name_length
FROM page_lengths
GROUP BY page_lengths.w_web_page_type
ORDER BY page_count DESC
