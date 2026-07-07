WITH page_pairs AS (
    SELECT
        wp1.w_web_page_type,
        wp1.w_web_page_name AS page_name_1,
        wp2.w_web_page_name AS page_name_2
    FROM web_pages wp1
    JOIN web_pages wp2
        ON wp1.w_web_page_type = wp2.w_web_page_type
        AND wp1.w_web_page_id < wp2.w_web_page_id
)
SELECT
    w_web_page_type,
    COUNT(*) AS pair_count,
    MIN(page_name_1) AS example_page_name_1,
    MIN(page_name_2) AS example_page_name_2
FROM page_pairs
GROUP BY w_web_page_type
ORDER BY pair_count DESC
