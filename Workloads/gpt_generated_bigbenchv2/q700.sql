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
        w_web_page_name,
        name_len,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY name_len DESC) AS rn,
        COUNT(*) OVER (PARTITION BY w_web_page_type) AS type_page_count
    FROM page_lengths
)
SELECT
    w_web_page_type,
    type_page_count AS page_count,
    w_web_page_name AS longest_page_name,
    name_len AS longest_name_len
FROM ranked_pages
WHERE rn = 1
ORDER BY page_count DESC
LIMIT 5
