SELECT
    w_web_page_type,
    page_count,
    longest_page_id,
    longest_page_name,
    longest_name_len
FROM (
    SELECT
        w_web_page_type,
        count(*) OVER (PARTITION BY w_web_page_type) AS page_count,
        w_web_page_id AS longest_page_id,
        w_web_page_name AS longest_page_name,
        length(w_web_page_name) AS longest_name_len,
        row_number() OVER (PARTITION BY w_web_page_type ORDER BY length(w_web_page_name) DESC) AS rn
    FROM web_pages
) AS t
WHERE rn = 1
ORDER BY page_count DESC, w_web_page_type
