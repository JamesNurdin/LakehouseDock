WITH name_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_name IS NOT NULL
      AND w_web_page_type IS NOT NULL
),
ranked_names AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        name_len,
        row_number() OVER (PARTITION BY w_web_page_type ORDER BY name_len DESC) AS rn
    FROM name_lengths
)
SELECT
    w_web_page_type,
    COUNT(*) AS total_pages,
    SUM(CASE WHEN rn <= 3 THEN 1 ELSE 0 END) AS top_3_longest_pages,
    MAX(CASE WHEN rn = 1 THEN name_len END) AS longest_name_len
FROM ranked_names
GROUP BY w_web_page_type
ORDER BY total_pages DESC
