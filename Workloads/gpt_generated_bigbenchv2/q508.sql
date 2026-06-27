WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
),
type_stats AS (
    SELECT
        w_web_page_type,
        count(*) AS page_count,
        avg(name_len) AS avg_name_len,
        max(name_len) AS max_name_len,
        min(name_len) AS min_name_len
    FROM page_lengths
    GROUP BY w_web_page_type
),
ranked_pages AS (
    SELECT
        pl.w_web_page_type,
        pl.w_web_page_name,
        pl.name_len,
        ts.page_count,
        ts.avg_name_len,
        row_number() OVER (PARTITION BY pl.w_web_page_type ORDER BY pl.name_len DESC) AS name_len_rank
    FROM page_lengths pl
    JOIN type_stats ts
        ON pl.w_web_page_type = ts.w_web_page_type
)
SELECT
    w_web_page_type,
    w_web_page_name,
    name_len,
    page_count,
    avg_name_len,
    name_len_rank
FROM ranked_pages
WHERE name_len_rank <= 3
ORDER BY w_web_page_type, name_len_rank
