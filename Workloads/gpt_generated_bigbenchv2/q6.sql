/*
  Find the three longest‑named pages within each page type.
  The query first computes the length of each page name, then ranks pages
  by that length within their type, and finally returns the top three per type.
*/
WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_len
    FROM web_pages
),
ranked_pages AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        name_len,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY name_len DESC) AS rn
    FROM page_lengths
)
SELECT
    w_web_page_type,
    w_web_page_id,
    w_web_page_name,
    name_len
FROM ranked_pages
WHERE rn <= 3
ORDER BY w_web_page_type, rn
