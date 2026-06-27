WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_length
    FROM web_pages
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(name_length) AS avg_name_length,
    MAX(name_length) AS max_name_length,
    slice(array_agg(w_web_page_name ORDER BY name_length DESC), 1, 3) AS top_3_longest_names
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY page_count DESC
