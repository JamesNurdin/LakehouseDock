WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        row_number() OVER (PARTITION BY w_web_page_type ORDER BY length(w_web_page_name) DESC) AS rn_longest,
        row_number() OVER (PARTITION BY w_web_page_type ORDER BY length(w_web_page_name) ASC) AS rn_shortest
    FROM web_pages
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(name_len) AS avg_name_length,
    MIN(name_len) AS min_name_length,
    MAX(name_len) AS max_name_length,
    MAX(CASE WHEN rn_longest = 1 THEN w_web_page_name END) AS longest_page_name,
    MAX(CASE WHEN rn_shortest = 1 THEN w_web_page_name END) AS shortest_page_name
FROM page_lengths
GROUP BY w_web_page_type
ORDER BY page_count DESC
