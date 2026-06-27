WITH name_counts AS (
    SELECT
        w_web_page_type,
        w_web_page_name,
        COUNT(*) AS name_cnt
    FROM web_pages
    GROUP BY w_web_page_type, w_web_page_name
),
ranked_names AS (
    SELECT
        w_web_page_type,
        w_web_page_name,
        name_cnt,
        ROW_NUMBER() OVER (
            PARTITION BY w_web_page_type
            ORDER BY name_cnt DESC, w_web_page_name
        ) AS rn
    FROM name_counts
)
SELECT
    w_web_page_type,
    w_web_page_name AS most_common_name,
    name_cnt AS occurrences
FROM ranked_names
WHERE rn = 1
ORDER BY w_web_page_type
