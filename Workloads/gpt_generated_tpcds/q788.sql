WITH filtered_pages AS (
    SELECT
        wp.wp_creation_date_sk,
        wp.wp_access_date_sk,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_customer_sk,
        wp.wp_type
    FROM web_page wp
    WHERE wp.wp_type = 'product'
)
SELECT
    cd.d_year AS creation_year,
    cd.d_month_seq AS creation_month_seq,
    COUNT(*) AS page_count,
    AVG(fp.wp_char_count) AS avg_char_count,
    SUM(fp.wp_link_count) AS total_links,
    AVG(date_diff('day', cd.d_date, ad.d_date)) AS avg_lifetime_days,
    COUNT(DISTINCT fp.wp_customer_sk) AS distinct_customers
FROM filtered_pages fp
JOIN date_dim cd ON fp.wp_creation_date_sk = cd.d_date_sk
JOIN date_dim ad ON fp.wp_access_date_sk = ad.d_date_sk
WHERE cd.d_year = 2022
GROUP BY cd.d_year, cd.d_month_seq
ORDER BY cd.d_year, cd.d_month_seq
