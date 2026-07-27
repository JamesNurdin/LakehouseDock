WITH refunded AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        SUM(wr.wr_net_loss) AS metric_value,
        CAST('net_loss' AS varchar) AS metric_type,
        (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk) AS transaction_count
    FROM
        customer c
    JOIN
        web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE
        c.c_last_review_date > 2452500
        AND wr.wr_return_amt > 100
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
), returning AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        SUM(wr.wr_fee) AS metric_value,
        CAST('fee' AS varchar) AS metric_type,
        (SELECT COUNT(*) FROM web_returns wr3 WHERE wr3.wr_returning_customer_sk = c.c_customer_sk) AS transaction_count
    FROM
        customer c
    JOIN
        web_returns wr
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_month = 7
        AND wr.wr_fee > 20
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
)
SELECT * FROM refunded
UNION ALL
SELECT * FROM returning
ORDER BY metric_value DESC, metric_type, customer_sk
LIMIT 100
