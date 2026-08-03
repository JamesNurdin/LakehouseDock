WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),

refunded AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(*) AS return_cnt
    FROM sampled_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_tax > 5.00
    GROUP BY cr.cr_refunded_customer_sk
    HAVING COUNT(*) >= 2
),

returning AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(*) AS return_cnt
    FROM sampled_returns cr
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_tax > 5.00
    GROUP BY cr.cr_returning_customer_sk
    HAVING COUNT(*) >= 2
),

exclusive_refunded AS (
    SELECT customer_sk, total_amount, return_cnt
    FROM refunded
    EXCEPT
    SELECT customer_sk, total_amount, return_cnt
    FROM returning
),

combined AS (
    SELECT customer_sk, total_amount, return_cnt, 'refunded' AS role
    FROM exclusive_refunded
    UNION ALL
    SELECT customer_sk, total_amount, return_cnt, 'returning' AS role
    FROM returning
),

ranked AS (
    SELECT
        c.customer_sk,
        c.total_amount,
        c.return_cnt,
        c.role,
        ROW_NUMBER() OVER (PARTITION BY c.role ORDER BY c.total_amount DESC) AS rn,
        (SELECT MAX(total_amount) FROM exclusive_refunded) AS max_exclusive_amount
    FROM combined c
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_return_amount = c.total_amount
          AND cr.cr_return_tax > 5.00
    )
)

SELECT
    r.customer_sk,
    r.total_amount,
    r.return_cnt,
    r.role,
    r.max_exclusive_amount
FROM ranked r
WHERE r.rn <= 5
ORDER BY r.role, r.total_amount DESC
LIMIT 100
