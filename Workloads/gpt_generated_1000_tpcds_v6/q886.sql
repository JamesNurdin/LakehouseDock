WITH refunded AS (
    SELECT
        cr.cr_return_amount,
        CASE WHEN cr.cr_store_credit > 100 THEN 'HIGH' ELSE 'LOW' END AS credit_category
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_amount > 50
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
            AND cr2.cr_fee > 70
      )
),
returning AS (
    SELECT
        cr.cr_return_amount,
        CASE WHEN cr.cr_fee > 80 THEN 'EXPENSIVE' ELSE 'NORMAL' END AS fee_category
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE cr.cr_store_credit BETWEEN 50 AND 200
      AND c.c_birth_month IN (1, 8, 12)
)
SELECT category,
       cnt,
       total_return_amount
FROM (
    SELECT
        credit_category AS category,
        COUNT(*) AS cnt,
        SUM(cr_return_amount) AS total_return_amount
    FROM refunded
    GROUP BY credit_category

    UNION ALL

    SELECT
        fee_category AS category,
        COUNT(*) AS cnt,
        SUM(cr_return_amount) AS total_return_amount
    FROM returning
    GROUP BY fee_category
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
