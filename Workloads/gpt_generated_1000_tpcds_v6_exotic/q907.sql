WITH agg_returns AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cr.cr_returning_customer_sk,
        wr.wr_returning_customer_sk,
        SUM(cr.cr_return_amount) AS sum_cr_return_amount,
        SUM(wr.wr_return_amt) AS sum_wr_return_amt,
        COUNT(*) AS txn_count
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
        cr.cr_return_quantity > 0
        AND cr.cr_return_amount > 10
        AND cr.cr_returning_customer_sk IN (2452686, 10068871, 9938342)
        AND r.r_reason_id = 'AAAAAAAABBAAAAAA'
        AND wr.wr_refunded_addr_sk NOT IN (2453001, 3580506)
        AND wr.wr_return_quantity <= 5
        AND cr.cr_fee BETWEEN 0 AND 100
    GROUP BY
        r.r_reason_desc,
        cr.cr_returning_customer_sk,
        wr.wr_returning_customer_sk
)
SELECT
    reason_desc,
    cr_returning_customer_sk,
    wr_returning_customer_sk,
    SUM(sum_cr_return_amount) AS total_cr_return_amount,
    SUM(sum_wr_return_amt) AS total_wr_return_amt,
    SUM(txn_count) AS total_txn,
    AVG(sum_cr_return_amount) AS avg_cr_return_amount,
    AVG(sum_wr_return_amt) AS avg_wr_return_amount
FROM agg_returns
GROUP BY GROUPING SETS (
    (reason_desc, cr_returning_customer_sk, wr_returning_customer_sk),
    (reason_desc, cr_returning_customer_sk),
    (reason_desc),
    ()
)
HAVING SUM(sum_cr_return_amount) > 100
ORDER BY total_cr_return_amount DESC
LIMIT 100
