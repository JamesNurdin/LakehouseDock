WITH sales_agg AS (
    SELECT 
        s.s_store_id AS store_id,
        d.d_date AS transaction_date,
        SUM(ss.ss_ext_sales_price) AS amount,
        'sales' AS transaction_type
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_date
),
returns_agg AS (
    SELECT 
        s.s_store_id AS store_id,
        d.d_date AS transaction_date,
        SUM(sr.sr_return_amt) AS amount,
        'return' AS transaction_type
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_date
)
SELECT store_id, transaction_date, amount, transaction_type
FROM sales_agg
UNION ALL
SELECT store_id, transaction_date, amount, transaction_type
FROM returns_agg
ORDER BY store_id, transaction_date, transaction_type
LIMIT 100
