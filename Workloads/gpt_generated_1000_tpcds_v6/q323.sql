WITH sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_year
),
returns_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_year
)
SELECT
    store_id,
    year,
    total_sales,
    CAST(NULL AS decimal(7,2)) AS total_returns,
    'sales' AS source
FROM sales_agg
UNION ALL
SELECT
    store_id,
    year,
    CAST(NULL AS decimal(7,2)) AS total_sales,
    total_returns,
    'returns' AS source
FROM returns_agg
ORDER BY store_id, year, source
LIMIT 100
