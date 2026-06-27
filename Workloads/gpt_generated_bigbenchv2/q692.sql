WITH page_stats AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        row_number() OVER (PARTITION BY w_web_page_type ORDER BY length(w_web_page_name) DESC) AS rn,
        count(*) OVER (PARTITION BY w_web_page_type) AS total_pages,
        avg(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS avg_name_len
    FROM web_pages
)
SELECT
    w_web_page_id,
    w_web_page_name,
    w_web_page_type,
    name_len,
    total_pages,
    avg_name_len,
    rn
FROM page_stats
WHERE rn <= 5
ORDER BY w_web_page_type, rn
