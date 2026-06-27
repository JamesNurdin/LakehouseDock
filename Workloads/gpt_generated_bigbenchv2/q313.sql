WITH page_stats AS (
    SELECT
        w_web_page_type,
        substring(w_web_page_name, 1, 1) AS first_letter,
        COUNT(*) AS page_count,
        AVG(length(w_web_page_name)) AS avg_name_len,
        MIN(w_web_page_id) AS min_id,
        MAX(w_web_page_id) AS max_id
    FROM web_pages
    GROUP BY w_web_page_type, substring(w_web_page_name, 1, 1)
)
SELECT
    w_web_page_type,
    first_letter,
    page_count,
    avg_name_len,
    min_id,
    max_id,
    ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY page_count DESC) AS rank_within_type
FROM page_stats
ORDER BY w_web_page_type, rank_within_type
LIMIT 50
