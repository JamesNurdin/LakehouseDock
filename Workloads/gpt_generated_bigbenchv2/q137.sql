WITH page_stats AS (
    SELECT
        w_web_page_type,
        count(*) AS page_count,
        avg(length(w_web_page_name)) AS avg_name_len,
        approx_percentile(length(w_web_page_name), 0.5) AS median_name_len
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    median_name_len,
    row_number() OVER (ORDER BY page_count DESC) AS rank_by_page_count
FROM page_stats
ORDER BY rank_by_page_count
LIMIT 10
