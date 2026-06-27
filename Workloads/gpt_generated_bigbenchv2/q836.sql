/*
  Analytical query on the web_pages table:
  - Computes the number of pages per page type.
  - Calculates average, maximum, and minimum length of the page names for each type.
  - Orders the result by the page count descending so the most common page types appear first.
*/
WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
)
SELECT
    w_web_page_type,
    count(*) AS page_count,
    avg(name_len) AS avg_name_len,
    max(name_len) AS max_name_len,
    min(name_len) AS min_name_len
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY page_count DESC
