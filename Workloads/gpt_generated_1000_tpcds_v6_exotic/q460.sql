WITH sales_cte AS (
    SELECT
        d.d_date AS transaction_date,
        'sales' AS source,
        SUM(cs.cs_ext_sales_price) AS amount
    FROM tpcds.catalog_sales cs
    INNER JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_department = 'Books'
      AND w.w_city = 'Oak Grove'
      AND d.d_year = 2001
    GROUP BY d.d_date
),
returns_cte AS (
    SELECT
        d.d_date AS transaction_date,
        'returns' AS source,
        SUM(sr.sr_return_amt) AS amount
    FROM tpcds.store_returns sr
    INNER JOIN tpcds.date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year > 1970
      AND d.d_year = 2001
    GROUP BY d.d_date
)
SELECT transaction_date, source, amount
FROM sales_cte
UNION ALL
SELECT transaction_date, source, amount
FROM returns_cte
ORDER BY transaction_date, source
LIMIT 100
