WITH name_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_name IS NOT NULL
)
SELECT
    name_lengths.w_web_page_type,
    COUNT(*) AS page_count,
    AVG(name_lengths.name_len) AS avg_name_len,
    MIN(name_lengths.name_len) AS min_name_len,
    MAX(name_lengths.name_len) AS max_name_len
FROM name_lengths
GROUP BY name_lengths.w_web_page_type
ORDER BY page_count DESC
