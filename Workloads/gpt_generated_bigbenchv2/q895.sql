/*
  Distribution of web page types – count of pages per type and the average length of the page name.
  Only the `web_pages` table is used, with grouping, a HAVING filter, and ordering.
*/
WITH page_type_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS page_count,
        AVG(LENGTH(w_web_page_name)) AS avg_name_length
    FROM web_pages
    GROUP BY w_web_page_type
    HAVING COUNT(*) > 100   -- keep only types that appear in at least 100 pages
)
SELECT
    w_web_page_type,
    page_count,
    avg_name_length
FROM page_type_stats
ORDER BY page_count DESC
