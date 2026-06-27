WITH type_counts AS (
    SELECT
        w_web_page_type,
        count(*) AS page_count,
        approx_distinct(w_web_page_name) AS distinct_name_count,
        avg(length(w_web_page_name)) AS avg_name_length
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    avg_name_length,
    page_count * 1.0 / distinct_name_count AS pages_per_distinct_name
FROM type_counts
ORDER BY page_count DESC
