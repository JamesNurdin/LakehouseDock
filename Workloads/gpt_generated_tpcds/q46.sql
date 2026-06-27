WITH page_activity AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_link_count,
        cd.d_year AS creation_year,
        cd.d_month_seq AS creation_month_seq,
        cd.d_date AS creation_date,
        ad.d_date AS access_date,
        date_diff('day', cd.d_date, ad.d_date) AS days_to_access
    FROM web_page wp
    JOIN date_dim cd
        ON wp.wp_creation_date_sk = cd.d_date_sk
    JOIN date_dim ad
        ON wp.wp_access_date_sk = ad.d_date_sk
    WHERE cd.d_year BETWEEN 2020 AND 2022
)
SELECT
    creation_year,
    creation_month_seq,
    wp_type,
    COUNT(*) AS pages_created,
    SUM(wp_char_count) AS total_characters,
    AVG(wp_char_count) AS avg_characters,
    SUM(CASE WHEN days_to_access <= 7 THEN 1 ELSE 0 END) AS accessed_within_7_days,
    ROUND(100.0 * SUM(CASE WHEN days_to_access <= 7 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_accessed_within_7_days,
    AVG(days_to_access) AS avg_days_to_access
FROM page_activity
WHERE days_to_access IS NOT NULL
GROUP BY creation_year, creation_month_seq, wp_type
ORDER BY creation_year DESC, creation_month_seq DESC, pages_created DESC
