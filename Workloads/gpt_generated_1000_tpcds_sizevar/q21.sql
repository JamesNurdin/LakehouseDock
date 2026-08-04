WITH sales_by_store AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        'sales' AS metric_type,
        SUM(ss.ss_net_paid) AS amount
    FROM store_sales ss
    RIGHT OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_year
),
returns_by_store AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        'returns' AS metric_type,
        SUM(sr.sr_return_amt) AS amount
    FROM store_returns sr
    RIGHT OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_year
),
combined AS (
    SELECT store_id, year, metric_type, amount FROM sales_by_store
    UNION ALL
    SELECT store_id, year, metric_type, amount FROM returns_by_store
)
SELECT
    store_id,
    year,
    metric_type,
    amount,
    ROW_NUMBER() OVER (ORDER BY store_id, metric_type) AS row_num
FROM combined
ORDER BY row_num
LIMIT 100
