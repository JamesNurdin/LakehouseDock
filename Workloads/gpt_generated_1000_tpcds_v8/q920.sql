WITH sampled_customer AS (
    SELECT *
    FROM customer
    TABLESAMPLE BERNOULLI (10)
),
filtered_customer AS (
    SELECT *
    FROM sampled_customer c
    WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
      AND c.c_first_name LIKE 'A%'
),
union_returns AS (
    SELECT wr.wr_refunded_customer_sk AS customer_sk,
           SUM(wr.wr_return_amt) AS total_amt
    FROM web_returns wr
    GROUP BY wr.wr_refunded_customer_sk

    UNION DISTINCT

    SELECT wr.wr_returning_customer_sk AS customer_sk,
           SUM(wr.wr_return_amt) AS total_amt
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
),
full_joined AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_customer_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_returned_date_sk
    FROM filtered_customer c
    FULL OUTER JOIN web_returns wr
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr_ex
        WHERE wr_ex.wr_refunded_customer_sk = c.c_customer_sk
          AND wr_ex.wr_return_amt > 1000
    )
),
aggregated AS (
    SELECT
        fj.c_customer_id,
        fj.c_first_name,
        fj.c_last_name,
        fj.c_email_address,
        COALESCE(SUM(fj.wr_return_amt), 0) AS total_return_amt,
        COUNT(fj.wr_return_amt) AS return_rows,
        ROW_NUMBER() OVER (PARTITION BY fj.c_customer_id ORDER BY COALESCE(SUM(fj.wr_return_amt), 0) DESC) AS rn,
        CASE
            WHEN COALESCE(SUM(fj.wr_return_amt), 0) > 500 THEN 'HighValue'
            ELSE 'LowValue'
        END AS value_category,
        regexp_extract(fj.c_email_address, '^([^@]+)@') AS email_user,
        (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_refunded_customer_sk = fj.c_customer_sk) AS total_returns_all,
        ur.total_amt AS union_total_amt
    FROM full_joined fj
    LEFT JOIN union_returns ur
      ON ur.customer_sk = fj.c_customer_sk
    GROUP BY
        fj.c_customer_id,
        fj.c_first_name,
        fj.c_last_name,
        fj.c_email_address,
        fj.c_customer_sk,
        ur.total_amt
)
SELECT *
FROM aggregated
WHERE rn = 1
ORDER BY total_return_amt DESC
LIMIT 100
