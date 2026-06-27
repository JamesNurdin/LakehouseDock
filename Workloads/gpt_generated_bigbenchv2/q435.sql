WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_length,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY LENGTH(w_web_page_name) DESC) AS rn
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(name_length) AS avg_name_length,
    MIN(name_length) AS min_name_length,
    MAX(name_length) AS max_name_length,
    MAX(CASE WHEN rn = 1 THEN name_length END) AS longest_name_length,
    MAX(CASE WHEN rn = 1 THEN w_web_page_name END) AS longest_page_name
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY page_count DESC
