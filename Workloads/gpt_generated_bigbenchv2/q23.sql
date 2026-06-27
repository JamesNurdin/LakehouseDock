/*
  Analytical query on the web_pages table:
  - Counts pages per type
  - Keeps only types with more than 5 pages
  - Shows the minimum and maximum page IDs per type
  - Returns the top three page names (by descending page ID) for each type
*/
WITH type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        MIN(w_web_page_id) AS min_id,
        MAX(w_web_page_id) AS max_id,
        ARRAY_AGG(w_web_page_name ORDER BY w_web_page_id DESC) AS name_by_desc_id
    FROM web_pages
    GROUP BY w_web_page_type
    HAVING COUNT(*) > 5
)
SELECT
    ts.w_web_page_type,
    ts.page_count,
    ts.min_id,
    ts.max_id,
    ts.name_by_desc_id[1] AS top_page_name,
    ts.name_by_desc_id[2] AS second_page_name,
    ts.name_by_desc_id[3] AS third_page_name
FROM type_stats ts
ORDER BY ts.page_count DESC
