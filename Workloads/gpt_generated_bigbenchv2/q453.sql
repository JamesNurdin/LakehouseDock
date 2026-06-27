WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_len
    FROM web_pages
    WHERE w_web_page_name IS NOT NULL
    GROUP BY w_web_page_type
),
ranked_stats AS (
    SELECT
        w_web_page_type,
        page_count,
        avg_name_len,
        RANK() OVER (ORDER BY page_count DESC) AS type_rank
    FROM page_stats
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    type_rank
FROM ranked_stats
WHERE type_rank <= 5
ORDER BY type_rank
