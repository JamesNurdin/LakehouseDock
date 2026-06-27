WITH page_stats AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        COUNT(*) OVER (PARTITION BY w_web_page_type) AS pages_per_type,
        AVG(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS avg_name_len,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY length(w_web_page_name) DESC) AS rn
    FROM web_pages
)
SELECT
    w_web_page_type,
    w_web_page_name,
    name_len,
    pages_per_type,
    avg_name_len
FROM page_stats
WHERE rn <= 5
ORDER BY w_web_page_type, name_len DESC
