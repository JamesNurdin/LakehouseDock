WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
),
ranked_pages AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        name_len,
        row_number() OVER (PARTITION BY w_web_page_type ORDER BY name_len DESC) AS rn,
        count(*) OVER (PARTITION BY w_web_page_type) AS total_pages
    FROM page_lengths
)
SELECT
    w_web_page_type,
    total_pages,
    w_web_page_id,
    w_web_page_name,
    name_len
FROM ranked_pages
WHERE rn <= 5
ORDER BY w_web_page_type, rn
