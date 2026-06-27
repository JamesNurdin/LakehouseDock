WITH type_stats AS (
    SELECT
        w_web_page_type,
        count(*) AS page_count,
        count(DISTINCT w_web_page_name) AS distinct_name_count,
        avg(length(w_web_page_name)) AS avg_name_length
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    avg_name_length,
    rank() OVER (ORDER BY page_count DESC) AS type_rank,
    sum(page_count) OVER (ORDER BY page_count DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_page_count
FROM type_stats
ORDER BY page_count DESC
