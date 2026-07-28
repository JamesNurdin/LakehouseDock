WITH sales AS (
    SELECT
        s.s_store_sk AS store_sk,
        s.s_store_id AS store_id,
        d.d_date AS sales_date,
        SUM(ss.ss_ext_sales_price) AS amount,
        'sale' AS trans_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2022
    GROUP BY s.s_store_sk, s.s_store_id, d.d_date
),
returns AS (
    SELECT
        s.s_store_sk AS store_sk,
        s.s_store_id AS store_id,
        d.d_date AS sales_date,
        SUM(sr.sr_return_amt) AS amount,
        'return' AS trans_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2022
    GROUP BY s.s_store_sk, s.s_store_id, d.d_date
),
combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
)
SELECT
    c.store_id,
    c.sales_date,
    c.trans_type,
    c.amount
FROM combined c
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss
    JOIN promotion p ON ss.ss_item_sk = p.p_item_sk
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE ss.ss_store_sk = c.store_sk
      AND d2.d_date = c.sales_date
      AND d2.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
)
ORDER BY c.sales_date DESC, c.amount DESC
LIMIT 100
