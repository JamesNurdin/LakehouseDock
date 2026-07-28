WITH agg_returns AS (
    SELECT
        c_refunded.c_birth_country AS refunded_country,
        c_returning.c_birth_country AS returning_country,
        wr.wr_reason_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
        ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    WHERE c_refunded.c_birth_country IN ('BAHAMAS', 'JORDAN', 'UKRAINE', 'TURKMENISTAN', 'TOGO')
      AND c_returning.c_birth_country NOT LIKE 'U%'
      AND c_refunded.c_last_review_date > 2452300
      AND wr.wr_reason_sk IN (11, 22, 45, 58, 41)
      AND wr.wr_return_quantity >= 1
      AND wr.wr_refunded_cash > 10
    GROUP BY c_refunded.c_birth_country, c_returning.c_birth_country, wr.wr_reason_sk
)
SELECT
    wr_reason_sk,
    AVG(total_return_amt) AS avg_return_amt,
    SUM(return_count) AS total_returns,
    SUM(total_refunded_cash) AS total_refunded_cash
FROM agg_returns
GROUP BY wr_reason_sk
HAVING SUM(total_refunded_cash) > 500
ORDER BY avg_return_amt DESC
LIMIT 100
