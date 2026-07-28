WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_refunded_cash,
        cr.cr_return_amount,
        cr.cr_returning_customer_sk,
        cr.cr_refunded_customer_sk,
        cust.c_customer_sk,
        cust.c_birth_day,
        cust.c_birth_month,
        cust.c_salutation,
        cust.c_first_shipto_date_sk
    FROM catalog_returns cr
    JOIN customer cust
        ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    WHERE cust.c_birth_day IN (16, 11, 20)
        AND cr.cr_return_quantity > 10
        AND cr.cr_refunded_cash > 100
        AND NOT EXISTS (
            SELECT 1
            FROM customer rc
            WHERE rc.c_customer_sk = cr.cr_returning_customer_sk
              AND rc.c_salutation = 'Mr.'
        )
),
agg AS (
    SELECT
        f.c_birth_month,
        f.c_salutation,
        COUNT(*) AS cnt_returns,
        SUM(f.cr_return_amount) AS total_return_amount,
        AVG(f.cr_refunded_cash) AS avg_refunded_cash
    FROM filtered f
    GROUP BY ROLLUP (f.c_birth_month, f.c_salutation)
    HAVING COUNT(*) > 0
)
SELECT
    a.c_birth_month,
    a.c_salutation,
    a.cnt_returns,
    a.total_return_amount,
    a.avg_refunded_cash,
    ROW_NUMBER() OVER (PARTITION BY a.c_birth_month ORDER BY a.total_return_amount DESC) AS rn_by_month
FROM agg a
ORDER BY a.c_birth_month NULLS LAST,
         a.c_salutation NULLS LAST,
         a.cnt_returns DESC
LIMIT 100
