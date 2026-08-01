WITH customer_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_month,
        c.c_first_sales_date_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_tax > 5.00
      AND sr.sr_refunded_cash >= 50.00
      AND c.c_birth_month IN (3, 4, 5)
      AND sr.sr_return_amt_inc_tax BETWEEN 20.00 AND 300.00
    GROUP BY c.c_customer_sk, c.c_birth_month, c.c_first_sales_date_sk
),
filtered_high_return AS (
    SELECT
        c_birth_month,
        total_return_amt,
        total_refunded_cash,
        avg_return_tax,
        return_cnt
    FROM customer_returns
    WHERE total_return_amt > 200.00
),
filtered_low_return AS (
    SELECT
        c_birth_month,
        total_return_amt,
        total_refunded_cash,
        avg_return_tax,
        return_cnt
    FROM customer_returns
    WHERE total_return_amt <= 200.00
),
combined AS (
    SELECT * FROM filtered_high_return
    UNION ALL
    SELECT * FROM filtered_low_return
)
SELECT
    c_birth_month,
    COUNT(*) AS num_customers,
    SUM(total_return_amt) AS sum_return_amt,
    AVG(total_refunded_cash) AS avg_refunded_cash,
    AVG(avg_return_tax) AS avg_return_tax_overall
FROM combined
GROUP BY c_birth_month
HAVING COUNT(*) >= 5
ORDER BY sum_return_amt DESC
LIMIT 100
