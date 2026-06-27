WITH page_metrics AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_len,
        COUNT(*) OVER (PARTITION BY w_web_page_type) AS page_count_by_type,
        AVG(LENGTH(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS avg_name_len_by_type,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY LENGTH(w_web_page_name) DESC) AS rn
    FROM web_pages
)
SELECT
    w_web_page_id,
    w_web_page_name,
    w_web_page_type,
    name_len,
    page_count_by_type,
    avg_name_len_by_type,
    rn
FROM page_metrics
WHERE rn <= 3
ORDER BY w_web_page_type, rn
