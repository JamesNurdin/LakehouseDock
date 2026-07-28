WITH sales_1998 AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        CAST('1998' AS VARCHAR) AS period
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 1998
    GROUP BY s.s_store_id, d.d_year
),
sales_1999 AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        CAST('1999' AS VARCHAR) AS period
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 1999
    GROUP BY s.s_store_id, d.d_year
)
SELECT store_id, year, total_sales, period
FROM sales_1998
UNION ALL
SELECT store_id, year, total_sales, period
FROM sales_1999
ORDER BY store_id, period
