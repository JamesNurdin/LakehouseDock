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
        COUNT(*) AS total_pages,
        COUNT(DISTINCT w_web_page_name) AS distinct_names,
        AVG(name_len) AS avg_name_len,
        MAX(name_len) AS max_name_len,
        MIN(name_len) AS min_name_len
    FROM page_lengths
    GROUP BY w_web_page_type
),
top_long_names AS (
    SELECT
        w_web_page_type,
        w_web_page_name,
        name_len,
        ROW_NUMBER() OVER (PARTITION BY w_web_page_type ORDER BY name_len DESC) AS rn
    FROM page_lengths
)
SELECT
    ts.w_web_page_type,
    ts.total_pages,
    ts.distinct_names,
    ts.avg_name_len,
    ts.max_name_len,
    ts.min_name_len,
    tn.w_web_page_name AS longest_page_name,
    tn.name_len AS longest_name_len
FROM type_stats ts
LEFT JOIN (
    SELECT w_web_page_type, w_web_page_name, name_len
    FROM top_long_names
    WHERE rn = 1
) tn
    ON ts.w_web_page_type = tn.w_web_page_type
ORDER BY ts.total_pages DESC
