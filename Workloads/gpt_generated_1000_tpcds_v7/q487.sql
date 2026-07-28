WITH refunded_returns AS (
    SELECT
        d.d_year AS return_year,
        'refunded' AS customer_role,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY d.d_year
),
returning_returns AS (
    SELECT
        d.d_year AS return_year,
        'returning' AS customer_role,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND c.c_preferred_cust_flag = 'N'
    GROUP BY d.d_year
)
SELECT
    return_year,
    customer_role,
    total_return_amount,
    return_count
FROM refunded_returns
UNION ALL
SELECT
    return_year,
    customer_role,
    total_return_amount,
    return_count
FROM returning_returns
ORDER BY return_year, customer_role
