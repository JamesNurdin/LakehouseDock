WITH page_stats AS (
    SELECT
        w_web_page_type,
        w_web_page_id,
        w_web_page_name,
        length(w_web_page_name) AS name_len,
        count(*) OVER (PARTITION BY w_web_page_type) AS type_page_cnt,
        row_number() OVER (PARTITION BY w_web_page_type ORDER BY length(w_web_page_name) DESC) AS rn
    FROM web_pages
)
SELECT
    w_web_page_type,
    type_page_cnt,
    w_web_page_id,
    w_web_page_name,
    name_len AS longest_name_length
FROM page_stats
WHERE rn = 1
ORDER BY type_page_cnt DESC
