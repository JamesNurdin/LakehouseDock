SELECT
    w_web_page_id,
    w_web_page_name,
    w_web_page_type,
    row_number() OVER (PARTITION BY w_web_page_type ORDER BY w_web_page_id) AS rank_in_type,
    count(*) OVER (PARTITION BY w_web_page_type) AS total_pages_in_type,
    avg(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS avg_name_len_in_type
FROM web_pages
WHERE w_web_page_name IS NOT NULL
ORDER BY w_web_page_type, rank_in_type
