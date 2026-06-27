/*
  Top 3 longest page names for each page type, together with the total number of pages per type.
  This query uses only the `web_pages` table, derives the length of each page name,
  ranks pages within each type, and computes a windowed count of pages per type.
*/
WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
),
ranked_pages AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        name_len,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY name_len DESC) AS rank_in_type,
        COUNT(*) OVER (PARTITION BY w_web_page_type) AS pages_per_type
    FROM page_lengths
)
SELECT
    w_web_page_type,
    w_web_page_id,
    w_web_page_name,
    name_len,
    rank_in_type,
    pages_per_type
FROM ranked_pages
WHERE rank_in_type <= 3
ORDER BY w_web_page_type, rank_in_type
