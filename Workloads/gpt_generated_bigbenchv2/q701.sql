/* Analytical query on web_pages: count of pages per type, average page‑name length, and share of total pages */
WITH type_agg AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_length
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    page_count,
    page_count * 1.0 / SUM(page_count) OVER () AS page_fraction,
    avg_name_length
FROM type_agg
ORDER BY page_count DESC
