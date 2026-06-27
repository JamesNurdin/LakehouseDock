WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) OVER (PARTITION BY w_web_page_type) AS page_count,
        AVG(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS avg_name_len,
        MIN(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS min_name_len,
        MAX(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS max_name_len,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY length(w_web_page_name) DESC) AS rn,
        w_web_page_id,
        w_web_page_name,
        length(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    min_name_len,
    max_name_len,
    w_web_page_id AS longest_page_id,
    w_web_page_name AS longest_page_name,
    name_len AS longest_name_len
FROM page_stats
WHERE rn = 1
ORDER BY page_count DESC
