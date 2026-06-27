WITH type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS total_pages,
        COUNT(DISTINCT w_web_page_name) AS distinct_names,
        AVG(length(w_web_page_name)) AS avg_name_len,
        MAX(length(w_web_page_name)) AS max_name_len,
        MIN(length(w_web_page_name)) AS min_name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    total_pages,
    distinct_names,
    avg_name_len,
    max_name_len,
    min_name_len,
    ROW_NUMBER() OVER (ORDER BY total_pages DESC) AS rank_by_pages
FROM type_stats
ORDER BY rank_by_pages
