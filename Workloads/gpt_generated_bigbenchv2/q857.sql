-- Analytical query on web_pages: per page type, show total pages, distinct page‑name count,
-- average and max page‑name length, and the longest page name
WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
)
SELECT
    w_web_page_type,
    total_pages,
    distinct_names,
    avg_name_len,
    max_name_len,
    longest_name,
    longest_name_len
FROM (
    SELECT
        w_web_page_type,
        w_web_page_name AS longest_name,
        name_len AS longest_name_len,
        COUNT(*) OVER (PARTITION BY w_web_page_type) AS total_pages,
        AVG(name_len) OVER (PARTITION BY w_web_page_type) AS avg_name_len,
        MAX(name_len) OVER (PARTITION BY w_web_page_type) AS max_name_len,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY name_len DESC, w_web_page_id) AS rn,
        (SELECT COUNT(DISTINCT w2.w_web_page_name)
         FROM web_pages w2
         WHERE w2.w_web_page_type = page_lengths.w_web_page_type) AS distinct_names
    FROM page_lengths
) t
WHERE rn = 1
ORDER BY total_pages DESC
