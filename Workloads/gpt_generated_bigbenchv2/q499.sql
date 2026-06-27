WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        MIN(w_web_page_id) AS min_page_id,
        MAX(w_web_page_id) AS max_page_id,
        max_by(w_web_page_name, length(w_web_page_name)) AS longest_page_name,
        MAX(length(w_web_page_name)) AS longest_name_length
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    min_page_id,
    max_page_id,
    longest_page_name,
    longest_name_length
FROM page_stats
ORDER BY page_count DESC
