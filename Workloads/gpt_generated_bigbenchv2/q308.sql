WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
),
ranked_pages AS (
    SELECT
        w_web_page_type,
        w_web_page_id,
        w_web_page_name,
        name_len,
        row_number() OVER (PARTITION BY w_web_page_type ORDER BY name_len DESC) AS rn
    FROM page_lengths
)
SELECT
    w_web_page_type,
    COUNT(*) AS total_pages,
    AVG(name_len) AS avg_name_len,
    MAX(name_len) AS max_name_len,
    MIN(name_len) AS min_name_len,
    ARRAY_AGG(w_web_page_name) FILTER (WHERE rn <= 3) AS top_3_longest_names
FROM ranked_pages
GROUP BY w_web_page_type
ORDER BY total_pages DESC
