WITH page_stats AS (
    SELECT
        w_web_page_type,
        w_web_page_id,
        w_web_page_name,
        LENGTH(w_web_page_name) AS name_len,
        ROW_NUMBER() OVER (
            PARTITION BY w_web_page_type
            ORDER BY LENGTH(w_web_page_name) DESC
        ) AS rn
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS total_pages,
    AVG(name_len) AS avg_name_length,
    MAX(name_len) AS max_name_length,
    MIN(name_len) AS min_name_length,
    MAX(CASE WHEN rn = 1 THEN w_web_page_name END) AS longest_page_name
FROM page_stats
GROUP BY w_web_page_type
ORDER BY total_pages DESC
