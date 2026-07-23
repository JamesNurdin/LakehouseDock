WITH country_page_stats AS (
    SELECT
        c.c_birth_country AS c_birth_country,
        SUM(wp.wp_max_ad_count) AS total_ads,
        COUNT(*) AS page_count,
        CAST(SUM(wp.wp_max_ad_count) AS DOUBLE) / COUNT(*) AS avg_ads_per_page
    FROM web_page wp
    JOIN date_dim d_create
        ON wp.wp_creation_date_sk = d_create.d_date_sk
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d_create.d_year = 2022
        AND d_create.d_current_quarter = 'Y'
        AND wp.wp_autogen_flag = 'N'
        AND wp.wp_max_ad_count > 0
        AND c.c_birth_country IN ('SWITZERLAND', 'CYPRUS', 'RWANDA')
        AND EXISTS (
            SELECT 1
            FROM date_dim d_access
            WHERE wp.wp_access_date_sk = d_access.d_date_sk
                AND d_access.d_holiday = 'Y'
        )
    GROUP BY c.c_birth_country
)
SELECT
    c_birth_country,
    total_ads,
    page_count,
    avg_ads_per_page
FROM (
    SELECT
        c_birth_country,
        total_ads,
        page_count,
        avg_ads_per_page
    FROM country_page_stats
) AS final
WHERE avg_ads_per_page > 1
ORDER BY avg_ads_per_page DESC
LIMIT 100
