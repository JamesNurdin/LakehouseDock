/*
   Analytical query on the web_pages table:
   - Computes per‑page‑type statistics (total pages, average/maximum/minimum name length).
   - Returns the five longest page names for each type.
   - Uses only the web_pages table and window functions; no joins are performed.
*/
WITH page_stats AS (
    SELECT
        w_web_page_type,
        w_web_page_name,
        length(w_web_page_name) AS name_len,
        row_number() OVER (
            PARTITION BY w_web_page_type
            ORDER BY length(w_web_page_name) DESC, w_web_page_id
        ) AS rn,
        count(*) OVER (PARTITION BY w_web_page_type) AS total_pages,
        avg(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS avg_name_len,
        max(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS max_name_len,
        min(length(w_web_page_name)) OVER (PARTITION BY w_web_page_type) AS min_name_len
    FROM web_pages
)
SELECT
    w_web_page_type,
    total_pages,
    avg_name_len,
    max_name_len,
    min_name_len,
    array_agg(w_web_page_name ORDER BY name_len DESC) FILTER (WHERE rn <= 5) AS top_5_longest_page_names
FROM page_stats
GROUP BY
    w_web_page_type,
    total_pages,
    avg_name_len,
    max_name_len,
    min_name_len
ORDER BY total_pages DESC
