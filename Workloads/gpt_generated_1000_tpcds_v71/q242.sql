WITH q1 AS (
    SELECT
        wr.wr_returning_customer_sk AS customer_sk,
        'current' AS quarter_flag,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_current_quarter = 'Y'
    GROUP BY wr.wr_returning_customer_sk
),
q2 AS (
    SELECT
        wr.wr_returning_customer_sk AS customer_sk,
        'previous' AS quarter_flag,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_current_quarter = 'N' AND d.d_fy_quarter_seq = 13
    GROUP BY wr.wr_returning_customer_sk
),
combined AS (
    SELECT * FROM q1
    UNION ALL
    SELECT * FROM q2
)
SELECT
    customer_sk,
    quarter_flag,
    total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY quarter_flag ORDER BY total_return_amt DESC) AS rn
FROM combined
ORDER BY quarter_flag, rn
LIMIT 100
