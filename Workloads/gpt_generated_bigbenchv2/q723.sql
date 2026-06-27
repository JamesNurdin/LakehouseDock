/*
  Analytical query on the web_pages table:
  - For each web page type, compute the total number of pages, the average
    length of page names, and the maximum name length.
  - Return the page (its id and name) that has the longest name within each type.
*/
WITH page_stats AS (
    SELECT
        w_web_page_id,
        w_web_page_type,
        w_web_page_name,
        length(w_web_page_name) AS name_len,
        COUNT(*) OVER (PARTITION BY w_web_page_type) AS page_count,
        AVG(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS avg_name_len,
        MAX(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS max_name_len,
        ROW_NUMBER() OVER (
            PARTITION BY w_web_page_type
            ORDER BY length(w_web_page_name) DESC, w_web_page_name
        ) AS rn
    FROM web_pages
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_len,
    max_name_len,
    w_web_page_id   AS longest_page_id,
    w_web_page_name AS longest_page_name,
    name_len        AS longest_name_len
FROM page_stats
WHERE rn = 1
ORDER BY w_web_page_type
