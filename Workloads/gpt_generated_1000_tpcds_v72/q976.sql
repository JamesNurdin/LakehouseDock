WITH sales_2020 AS (
    SELECT
        s.s_store_id          AS store_id,
        d.d_year              AS year,
        SUM(ss.ss_ext_sales_price) AS total_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        'sales'               AS source
    FROM store_sales ss
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY s.s_store_id, d.d_year
),
returns_2020 AS (
    SELECT
        s.s_store_id          AS store_id,
        d.d_year              AS year,
        SUM(sr.sr_return_amt) AS total_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS transaction_count,
        'returns'             AS source
    FROM store_returns sr
    INNER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY s.s_store_id, d.d_year
)
SELECT *
FROM sales_2020
UNION ALL
SELECT *
FROM returns_2020
ORDER BY total_amount DESC
LIMIT 100
