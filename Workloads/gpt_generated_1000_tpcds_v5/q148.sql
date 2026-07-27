WITH high_income_customers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CASE
            WHEN ib.ib_upper_bound > 130000 THEN 'Very High'
            WHEN ib.ib_upper_bound > 100000 THEN 'High'
            ELSE 'Medium'
        END AS income_category,
        (
            SELECT COUNT(*)
            FROM web_page wp2
            WHERE wp2.wp_customer_sk = c.c_customer_sk
        ) AS page_count,
        'high_income' AS source
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_credit_rating = 'Excellent'
      AND ib.ib_upper_bound > 100000
),
active_web_customers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CASE
            WHEN (
                SELECT COUNT(*)
                FROM web_page wp2
                WHERE wp2.wp_customer_sk = c.c_customer_sk
            ) > 100 THEN 'Power User'
            WHEN (
                SELECT COUNT(*)
                FROM web_page wp2
                WHERE wp2.wp_customer_sk = c.c_customer_sk
            ) > 20 THEN 'Active'
            ELSE 'Low'
        END AS income_category,
        (
            SELECT COUNT(*)
            FROM web_page wp2
            WHERE wp2.wp_customer_sk = c.c_customer_sk
        ) AS page_count,
        'web_active' AS source
    FROM customer c
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_link_count > 50
    )
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    income_category,
    page_count,
    source
FROM (
    SELECT * FROM high_income_customers
    UNION ALL
    SELECT * FROM active_web_customers
) AS combined
ORDER BY page_count DESC, c_customer_id
LIMIT 100
