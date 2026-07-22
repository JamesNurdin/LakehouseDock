WITH target_customers AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_month
    FROM customer c
    WHERE c.c_birth_month = 6
)

SELECT
    metric,
    customer_id,
    amount,
    txn_count
FROM (
    SELECT
        'sales' AS metric,
        tc.c_customer_id AS customer_id,
        SUM(ss.ss_net_paid) AS amount,
        COUNT(*) AS txn_count
    FROM target_customers tc
    JOIN store_sales ss ON ss.ss_customer_sk = tc.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND ss.ss_sold_date_sk BETWEEN 2450011 AND 2451408
    GROUP BY tc.c_customer_id

    UNION ALL

    SELECT
        'returns' AS metric,
        tc.c_customer_id AS customer_id,
        SUM(cr.cr_return_amount) AS amount,
        COUNT(*) AS txn_count
    FROM target_customers tc
    JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = tc.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
      AND cr.cr_returned_date_sk BETWEEN 2450011 AND 2451408
    GROUP BY tc.c_customer_id
) AS combined
ORDER BY amount DESC
LIMIT 100
