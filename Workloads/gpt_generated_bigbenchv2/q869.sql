WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_type,
        w_web_page_name,
        LENGTH(w_web_page_name) AS name_len,
        SUBSTR(w_web_page_name, 1, 1) AS first_char
    FROM web_pages
    WHERE w_web_page_name IS NOT NULL
)
SELECT
    pl1.w_web_page_type,
    COUNT(*) AS page_count,
    COUNT(DISTINCT pl1.w_web_page_id) AS distinct_page_count,
    AVG(pl1.name_len) AS avg_name_length,
    MAX(pl1.name_len) AS max_name_length,
    (
        SELECT sub.first_char
        FROM (
            SELECT first_char, COUNT(*) AS char_cnt
            FROM page_lengths AS pl2
            WHERE pl2.w_web_page_type = pl1.w_web_page_type
            GROUP BY first_char
            ORDER BY char_cnt DESC, first_char
            LIMIT 1
        ) sub
    ) AS most_common_initial
FROM page_lengths AS pl1
GROUP BY pl1.w_web_page_type
ORDER BY page_count DESC
