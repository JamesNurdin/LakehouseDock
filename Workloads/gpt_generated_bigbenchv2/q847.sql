/*
  Analytical query on the web_pages table:
  - Computes page count, distinct page IDs, and average page‑name length per page type.
  - Returns the top 3 longest page names for each type as an ordered array.
*/
WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_id) AS distinct_page_ids,
        AVG(LENGTH(w_web_page_name)) AS avg_name_length
    FROM web_pages
    GROUP BY w_web_page_type
),
top_pages AS (
    SELECT
        w_web_page_type,
        w_web_page_name,
        LENGTH(w_web_page_name) AS name_len,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY LENGTH(w_web_page_name) DESC) AS rn
    FROM web_pages
)
SELECT
    ps.w_web_page_type,
    ps.page_count,
    ps.distinct_page_ids,
    ps.avg_name_length,
    ARRAY_AGG(tp.w_web_page_name ORDER BY tp.name_len DESC) FILTER (WHERE tp.rn <= 3) AS top_3_longest_names
FROM page_stats ps
LEFT JOIN top_pages tp
    ON ps.w_web_page_type = tp.w_web_page_type
GROUP BY
    ps.w_web_page_type,
    ps.page_count,
    ps.distinct_page_ids,
    ps.avg_name_length
ORDER BY ps.page_count DESC
