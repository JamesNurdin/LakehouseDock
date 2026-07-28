WITH sales AS (
    SELECT
        'sale' AS transaction_type,
        c.c_birth_day AS birth_day,
        cs.cs_net_paid AS amount,
        cs.cs_quantity AS quantity
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_net_paid > 100
      AND c.c_birth_day BETWEEN 1 AND 28
),
returns AS (
    SELECT
        'return' AS transaction_type,
        c.c_birth_day AS birth_day,
        sr.sr_return_amt AS amount,
        sr.sr_return_quantity AS quantity
    FROM tpcds.store_returns sr
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_amt > 50
      AND c.c_birth_day BETWEEN 1 AND 28
)
SELECT
    transaction_type,
    birth_day,
    SUM(amount) AS total_amount,
    SUM(quantity) AS total_quantity
FROM (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
) AS combined
GROUP BY GROUPING SETS (
    (transaction_type, birth_day),
    (transaction_type),
    ()
)
ORDER BY transaction_type, birth_day
LIMIT 100
