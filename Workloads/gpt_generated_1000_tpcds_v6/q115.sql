WITH sales AS (
    SELECT
        d.d_date AS transaction_date,
        c.c_customer_id AS customer_id,
        SUM(cs.cs_ext_sales_price) AS total_amount,
        'sale' AS transaction_type,
        NULL AS return_reason
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, c.c_customer_id
),
returns AS (
    SELECT
        d.d_date AS transaction_date,
        c.c_customer_id AS customer_id,
        SUM(wr.wr_return_amt) AS total_amount,
        'return' AS transaction_type,
        MIN(r.r_reason_desc) AS return_reason
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, c.c_customer_id
)
SELECT * FROM sales
UNION ALL
SELECT * FROM returns
ORDER BY transaction_date DESC, total_amount DESC
LIMIT 100
