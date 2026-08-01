/* Goal: Combine high‑value return customers from the catalog and store channels. Each sub‑query returns customers whose total return amount exceeds the overall average return amount for that channel (scalar subquery). The results are unioned, ordered by return amount, and limited to the top 100 rows. */
WITH catalog_top AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        'catalog' AS return_channel
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
    GROUP BY c.c_customer_id
    HAVING SUM(cr.cr_return_amount) > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
    )
),
store_top AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(sr.sr_return_amt) AS total_return_amount,
        'store' AS return_channel
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
    GROUP BY c.c_customer_id
    HAVING SUM(sr.sr_return_amt) > (
        SELECT AVG(sr2.sr_return_amt)
        FROM store_returns sr2
    )
)
SELECT
    customer_id,
    total_return_amount,
    return_channel
FROM (
    SELECT customer_id, total_return_amount, return_channel FROM catalog_top
    UNION ALL
    SELECT customer_id, total_return_amount, return_channel FROM store_top
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
