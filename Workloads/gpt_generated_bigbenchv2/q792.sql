WITH page_metrics AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY w_web_page_id DESC) AS rank_within_type,
        COUNT(*) OVER (PARTITION BY w_web_page_type) AS pages_per_type,
        AVG(LENGTH(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS avg_name_len,
        MIN(w_web_page_id) OVER (PARTITION BY w_web_page_type) AS min_page_id,
        MAX(w_web_page_id) OVER (PARTITION BY w_web_page_type) AS max_page_id
    FROM web_pages
)
SELECT
    w_web_page_type,
    pages_per_type,
    avg_name_len,
    min_page_id,
    max_page_id,
    w_web_page_id,
    w_web_page_name,
    rank_within_type
FROM page_metrics
WHERE rank_within_type <= 5
ORDER BY w_web_page_type, rank_within_type
