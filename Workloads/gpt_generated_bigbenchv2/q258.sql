WITH page_metrics AS (
    SELECT
        w_web_page_type,
        count(*) AS page_count,
        avg(length(w_web_page_name)) AS avg_name_len,
        approx_percentile(length(w_web_page_name), 0.5) AS median_name_len,
        max(length(w_web_page_name)) AS max_name_len,
        min(length(w_web_page_name)) AS min_name_len
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    median_name_len,
    max_name_len,
    min_name_len,
    round(page_count * 100.0 / sum(page_count) OVER (), 2) AS pct_of_total_pages
FROM page_metrics
ORDER BY page_count DESC
