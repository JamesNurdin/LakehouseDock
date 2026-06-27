/*
  Analytical query on the web_pages table:
  - Counts pages per type
  - Computes average, minimum, and maximum page‑name length per type
  - Calculates each type's share of the total page count
*/
WITH page_stats AS (
    SELECT
        w.w_web_page_type,
        COUNT(*) AS page_cnt,
        AVG(LENGTH(w.w_web_page_name)) AS avg_name_len,
        MIN(LENGTH(w.w_web_page_name)) AS min_name_len,
        MAX(LENGTH(w.w_web_page_name)) AS max_name_len
    FROM web_pages w
    GROUP BY w.w_web_page_type
)
SELECT
    ps.w_web_page_type,
    ps.page_cnt,
    ps.avg_name_len,
    ps.min_name_len,
    ps.max_name_len,
    ROUND(100.0 * ps.page_cnt / SUM(ps.page_cnt) OVER (), 2) AS pct_of_total_pages
FROM page_stats ps
ORDER BY ps.page_cnt DESC
