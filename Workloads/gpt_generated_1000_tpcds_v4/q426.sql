WITH catalog_ret AS (
    SELECT DISTINCT
        c.c_customer_id AS customer_id,
        cr.cr_return_amount AS return_amt,
        d.d_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
),
web_ret AS (
    SELECT DISTINCT
        c.c_customer_id AS customer_id,
        wr.wr_return_amt AS return_amt,
        d.d_year
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
)
SELECT
    combined.customer_id,
    SUM(combined.return_amt) AS total_return_amount
FROM (
    SELECT customer_id, return_amt FROM catalog_ret
    UNION ALL
    SELECT customer_id, return_amt FROM web_ret
) AS combined
GROUP BY combined.customer_id
ORDER BY total_return_amount DESC
LIMIT 100
