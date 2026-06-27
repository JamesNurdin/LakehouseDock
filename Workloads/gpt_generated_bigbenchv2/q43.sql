WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        floor(length(w_web_page_name) / 10) * 10 AS length_bucket
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    length_bucket,
    COUNT(*) AS page_cnt,
    AVG(name_len) AS avg_name_len,
    MIN(name_len) AS min_name_len,
    MAX(name_len) AS max_name_len
FROM page_lengths
GROUP BY w_web_page_type, length_bucket
ORDER BY w_web_page_type, length_bucket
