WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
),
page_aggregates AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(name_len) AS avg_name_len,
        MAX(name_len) AS max_name_len,
        MIN(name_len) AS min_name_len
    FROM page_lengths
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    max_name_len,
    min_name_len
FROM page_aggregates
ORDER BY page_count DESC
