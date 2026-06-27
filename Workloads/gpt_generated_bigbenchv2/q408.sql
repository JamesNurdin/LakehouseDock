/*
  Analytical query on the web_pages table:
  - Counts pages per type
  - Shows distinct page‑name count per type
  - Computes average, min, and max page‑name length per type
  - Ranks page types by total page count
*/
WITH page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_length,
        MIN(LENGTH(w_web_page_name)) AS min_name_length,
        MAX(LENGTH(w_web_page_name)) AS max_name_length
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    distinct_name_count,
    avg_name_length,
    min_name_length,
    max_name_length,
    RANK() OVER (ORDER BY page_count DESC) AS type_rank
FROM page_stats
ORDER BY page_count DESC
