/*
  For each web page type, list the top‑3 longest page names together with
  the total number of pages of that type and the average page‑name length.
*/
WITH ranked_pages AS (
    SELECT
        w_web_page_type,
        w_web_page_name,
        length(w_web_page_name) AS name_length,
        count(*) OVER (PARTITION BY w_web_page_type) AS pages_per_type,
        avg(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS avg_name_len_per_type,
        row_number() OVER (PARTITION BY w_web_page_type ORDER BY length(w_web_page_name) DESC) AS name_rank
    FROM web_pages
)
SELECT
    w_web_page_type,
    w_web_page_name,
    name_length,
    pages_per_type,
    avg_name_len_per_type,
    name_rank
FROM ranked_pages
WHERE name_rank <= 3
ORDER BY w_web_page_type, name_rank
