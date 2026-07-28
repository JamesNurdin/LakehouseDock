WITH returns AS (
    SELECT DISTINCT
        c.c_customer_id,
        'RETURN' AS activity_type,
        d.d_date AS activity_date
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2023-01-01'
      AND d.d_date < DATE '2023-04-01'
      AND cr.cr_return_quantity > 0
),

purchases AS (
    SELECT DISTINCT
        c.c_customer_id,
        'PURCHASE' AS activity_type,
        d.d_date AS activity_date
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2023-01-01'
      AND d.d_date < DATE '2023-04-01'
      AND ss.ss_quantity > 0
)
SELECT DISTINCT
    activity_type,
    c_customer_id,
    activity_date
FROM (
    SELECT * FROM returns
    UNION ALL
    SELECT * FROM purchases
) AS combined
ORDER BY activity_date DESC, activity_type
LIMIT 100
