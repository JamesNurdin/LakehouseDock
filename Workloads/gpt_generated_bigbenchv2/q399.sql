WITH page_metrics AS (
    SELECT
        w_web_page_type,
        count(*) AS page_count,
        count(DISTINCT w_web_page_name) AS distinct_name_count,
        avg(length(w_web_page_name)) AS avg_name_length,
        max(length(w_web_page_name)) AS max_name_length,
        min(length(w_web_page_name)) AS min_name_length
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    avg_name_length,
    max_name_length,
    min_name_length,
    (distinct_name_count * 100.0 / page_count) AS distinct_name_percentage,
    rank() OVER (ORDER BY page_count DESC) AS type_rank
FROM page_metrics
ORDER BY page_count DESC
