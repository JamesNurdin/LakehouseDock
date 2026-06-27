WITH page_metrics AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
), ranked AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        name_len,
        row_number() OVER (PARTITION BY w_web_page_type ORDER BY name_len DESC) AS rn,
        sum(name_len) OVER (PARTITION BY w_web_page_type) AS total_name_len,
        count(*) OVER (PARTITION BY w_web_page_type) AS total_pages
    FROM page_metrics
)
SELECT
    w_web_page_type,
    w_web_page_id,
    w_web_page_name,
    name_len,
    total_name_len,
    total_pages
FROM ranked
WHERE rn <= 3
ORDER BY w_web_page_type, name_len DESC
