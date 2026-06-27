WITH page_stats AS (
    SELECT
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
),
type_agg AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(name_len) AS avg_name_len,
        MAX(name_len) AS max_name_len,
        MIN(name_len) AS min_name_len,
        APPROX_PERCENTILE(name_len, 0.5) AS median_name_len
    FROM page_stats
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    max_name_len,
    min_name_len,
    median_name_len,
    RANK() OVER (ORDER BY page_count DESC) AS rank_by_page_count
FROM type_agg
ORDER BY page_count DESC
