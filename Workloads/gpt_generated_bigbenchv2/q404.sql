WITH page_type_agg AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_id) AS distinct_page_ids,
        MIN(w_web_page_id) AS min_page_id,
        MAX(w_web_page_id) AS max_page_id,
        AVG(LENGTH(w_web_page_name)) AS avg_name_len
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_page_ids,
    min_page_id,
    max_page_id,
    avg_name_len,
    RANK() OVER (ORDER BY page_count DESC) AS type_rank,
    SUM(page_count) OVER (
        ORDER BY page_count DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_page_count
FROM page_type_agg
ORDER BY page_count DESC
