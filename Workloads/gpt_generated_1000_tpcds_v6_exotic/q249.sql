/* goal: Compare total Net Paid revenue per birth country under two different customer/transaction filters and combine the results */
SELECT
    birth_country,
    total_net_paid,
    source
FROM (
    SELECT
        c.c_birth_country AS birth_country,
        SUM(ss.ss_net_paid) AS total_net_paid,
        'recent_review' AS source
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_last_review_date >= 2452400
    GROUP BY c.c_birth_country

    UNION ALL

    SELECT
        c.c_birth_country AS birth_country,
        SUM(ss.ss_net_paid) AS total_net_paid,
        'high_spend' AS source
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_net_paid >= 2000
      AND c.c_birth_country IN ('KOREA', 'SWITZERLAND')
    GROUP BY c.c_birth_country
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
