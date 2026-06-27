/*
  Find the longest page name for each page type together with type‑level statistics.
  The query uses only the `web_pages` table, no joins, and leverages window functions
  for aggregation, filtering, and ordering.
*/
WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_len,
        AVG(LENGTH(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS avg_len_by_type,
        APPROX_PERCENTILE(LENGTH(w_web_page_name), 0.5) OVER (PARTITION BY w_web_page_type) AS median_len_by_type,
        MAX(LENGTH(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS max_len_by_type,
        COUNT(*) OVER (PARTITION BY w_web_page_type) AS page_count_by_type
    FROM web_pages
)
SELECT
    w_web_page_type,
    w_web_page_id,
    w_web_page_name,
    name_len,
    avg_len_by_type,
    median_len_by_type,
    max_len_by_type,
    page_count_by_type
FROM page_lengths
WHERE name_len = max_len_by_type
ORDER BY w_web_page_type
