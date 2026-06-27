WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY length(w_web_page_name) DESC) AS rn
    FROM web_pages
),
page_stats AS (
    SELECT
        w_web_page_type,
        COUNT(*) AS total_pages,
        AVG(name_len) AS avg_name_len,
        ARRAY_AGG(w_web_page_name) FILTER (WHERE rn <= 3) AS top_3_longest_names
    FROM page_lengths
    GROUP BY w_web_page_type
)
SELECT
    w_web_page_type,
    total_pages,
    avg_name_len,
    ROW_NUMBER() OVER (ORDER BY total_pages DESC) AS type_rank,
    top_3_longest_names
FROM page_stats
ORDER BY type_rank
