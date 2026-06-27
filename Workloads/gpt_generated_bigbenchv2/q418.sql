/*
   Top 5 longest‑named web pages per type, together with per‑type statistics.
   Uses window functions for aggregation and ranking without any joins.
*/
WITH page_metrics AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_length,
        COUNT(*) OVER (PARTITION BY w_web_page_type) AS pages_per_type,
        AVG(LENGTH(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS avg_name_length_in_type,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY LENGTH(w_web_page_name) DESC) AS rank_by_name_length
    FROM web_pages
    WHERE LENGTH(w_web_page_name) > 0
)
SELECT
    w_web_page_id,
    w_web_page_name,
    w_web_page_type,
    name_length,
    pages_per_type,
    avg_name_length_in_type,
    rank_by_name_length
FROM page_metrics
WHERE rank_by_name_length <= 5
ORDER BY w_web_page_type, rank_by_name_length
