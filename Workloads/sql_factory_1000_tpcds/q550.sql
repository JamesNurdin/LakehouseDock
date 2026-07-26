WITH wp_dates AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_creation_date_sk,
        wp.wp_access_date_sk,
        d_create.d_date AS creation_date,
        d_access.d_date AS access_date,
        date_diff('day', d_create.d_date, d_access.d_date) AS days_lag
    FROM web_page wp
    JOIN date_dim d_create
        ON wp.wp_creation_date_sk = d_create.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
)
SELECT
    wd.wp_web_page_sk,
    wd.wp_url,
    wd.wp_type,
    wd.days_lag,
    wd.wp_char_count,
    RANK() OVER (PARTITION BY wd.wp_type ORDER BY wd.wp_char_count DESC) AS char_count_rank,
    CASE
        WHEN wd.days_lag > 30 THEN 'LONG LAG'
        WHEN wd.days_lag > 7 THEN 'MEDIUM LAG'
        ELSE 'SHORT LAG'
    END AS lag_category,
    COALESCE(cc.cc_tax_percentage, 0) AS tax_percentage_on_creation_date
FROM wp_dates wd
LEFT JOIN call_center cc
    ON cc.cc_open_date_sk = wd.wp_creation_date_sk
WHERE wd.wp_char_count IS NOT NULL
ORDER BY wd.days_lag DESC
LIMIT 20
