WITH length_counts AS (
    SELECT
        w_web_page_type,
        length(w_web_page_name) AS name_len,
        count(*) AS cnt
    FROM web_pages
    GROUP BY w_web_page_type, length(w_web_page_name)
),
ranked_lengths AS (
    SELECT
        w_web_page_type,
        name_len,
        cnt,
        row_number() OVER (PARTITION BY w_web_page_type ORDER BY cnt DESC) AS rn
    FROM length_counts
)
SELECT
    w_web_page_type,
    name_len,
    cnt
FROM ranked_lengths
WHERE rn <= 3
ORDER BY w_web_page_type, rn
