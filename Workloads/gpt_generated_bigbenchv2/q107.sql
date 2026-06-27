/* Top 3 longest web page names per page type */
WITH ranked_pages AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_length,
        row_number() OVER (
            PARTITION BY w_web_page_type
            ORDER BY length(w_web_page_name) DESC
        ) AS rn
    FROM web_pages
)
SELECT
    w_web_page_type,
    w_web_page_id,
    w_web_page_name,
    name_length
FROM ranked_pages
WHERE rn <= 3
ORDER BY w_web_page_type, name_length DESC
