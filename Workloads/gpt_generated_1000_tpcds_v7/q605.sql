/* goal: Compare total return amounts per customer from catalog returns and store returns for high-value returns within a specific date range */
WITH catalog_ret AS (
    SELECT
        c.c_customer_id,
        cr.cr_return_amount,
        'Catalog' AS source
    FROM
        catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE
        cr.cr_return_amount > 100
        AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
),
store_ret AS (
    SELECT
        c.c_customer_id,
        sr.sr_return_amt,
        'Store' AS source
    FROM
        store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE
        sr.sr_return_amt > 100
        AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
),
combined AS (
    SELECT c_customer_id, cr_return_amount AS return_amount, source FROM catalog_ret
    UNION ALL
    SELECT c_customer_id, sr_return_amt AS return_amount, source FROM store_ret
)
SELECT
    c_customer_id,
    source,
    SUM(return_amount) AS total_return_amount,
    COUNT(*) AS return_count
FROM
    combined
GROUP BY
    c_customer_id,
    source
ORDER BY
    total_return_amount DESC
LIMIT 100
