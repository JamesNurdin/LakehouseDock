WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY length(w_web_page_name) DESC) AS rn
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS total_pages,
    AVG(name_len) AS avg_name_length,
    MAX(name_len) AS max_name_length,
    MIN(name_len) AS min_name_length,
    COUNT(CASE WHEN rn = 1 THEN 1 END) AS longest_name_count,
    MAX(CASE WHEN rn = 1 THEN name_len END) AS longest_name_length
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY total_pages DESC, w_web_page_type
