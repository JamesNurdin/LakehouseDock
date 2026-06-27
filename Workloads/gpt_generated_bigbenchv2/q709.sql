/*
   Analytical query on the web_pages table:
   - Counts pages per type
   - Calculates average, minimum, and maximum page‑name length per type
   - Returns the three longest page names for each type
*/
WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        row_number() OVER (
            PARTITION BY w_web_page_type
            ORDER BY length(w_web_page_name) DESC
        ) AS rn
    FROM web_pages
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(name_len) AS avg_name_len,
    MAX(name_len) AS max_name_len,
    MIN(name_len) AS min_name_len,
    array_agg(w_web_page_name ORDER BY name_len DESC)
        FILTER (WHERE rn <= 3) AS top_3_longest_names
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY page_count DESC
