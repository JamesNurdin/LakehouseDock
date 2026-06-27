SELECT
    w_web_page_type,
    type_cnt,
    avg_name_len,
    max_name_len,
    type_cnt * 1.0 / SUM(type_cnt) OVER () AS proportion,
    ROW_NUMBER() OVER (ORDER BY avg_name_len DESC) AS avg_len_rank
FROM (
    SELECT
        w_web_page_type,
        COUNT(*) AS type_cnt,
        AVG(LENGTH(w_web_page_name)) AS avg_name_len,
        MAX(LENGTH(w_web_page_name)) AS max_name_len
    FROM web_pages
    GROUP BY w_web_page_type
) t
ORDER BY proportion DESC
