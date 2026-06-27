WITH type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(length(w_web_page_name)) AS avg_name_len,
        MIN(length(w_web_page_name)) AS min_name_len,
        MAX(length(w_web_page_name)) AS max_name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    min_name_len,
    max_name_len,
    RANK() OVER (ORDER BY page_count DESC) AS type_rank_by_pages
FROM type_stats
ORDER BY page_count DESC
