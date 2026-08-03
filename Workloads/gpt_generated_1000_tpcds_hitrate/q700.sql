WITH store_ret AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(sr.sr_return_amt_inc_tax) AS total_return,
        CASE WHEN SUM(sr.sr_return_amt_inc_tax) > (
                SELECT AVG(sr2.sr_return_amt_inc_tax)
                FROM store_returns sr2
            ) THEN 'Above Avg' ELSE 'Below Avg' END AS return_level,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS rn
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%Parts missing%'
    GROUP BY c.c_customer_id
),
web_ret AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(wr.wr_return_amt_inc_tax) AS total_return,
        CASE WHEN SUM(wr.wr_return_amt_inc_tax) > (
                SELECT AVG(wr2.wr_return_amt_inc_tax)
                FROM web_returns wr2
            ) THEN 'Above Avg' ELSE 'Below Avg' END AS return_level,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(wr.wr_return_amt_inc_tax) DESC) AS rn
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%Did not like%'
    GROUP BY c.c_customer_id
)
SELECT
    intersected.customer_id,
    intersected.total_return,
    intersected.return_level
FROM (
    SELECT customer_id, total_return, return_level FROM store_ret
    INTERSECT
    SELECT customer_id, total_return, return_level FROM web_ret
) AS intersected
ORDER BY intersected.total_return DESC
LIMIT 100
