/*
Goal: Compare total catalog sales amount with total web return amount per catalog department for the year 2001, distinguishing the source (sales vs returns). The query uses a UNION ALL to stack the two aggregated result sets and includes an EXISTS subquery to restrict sales to departments that have at least one monthly catalog page.
*/
WITH sales_data AS (
    SELECT
        cp.cp_department AS department,
        d.d_year        AS sales_year,
        SUM(cs.cs_ext_sales_price) AS amount,
        'sales'         AS source
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d      ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_type = 'monthly'
              AND cp2.cp_catalog_page_sk = cp.cp_catalog_page_sk
        )
    GROUP BY cp.cp_department, d.d_year
),
returns_data AS (
    SELECT
        cp.cp_department AS department,
        d.d_year        AS sales_year,
        SUM(wr.wr_return_amt) AS amount,
        'returns'       AS source
    FROM web_returns wr
    JOIN date_dim d      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cp.cp_type IN ('monthly', 'quarterly')
    GROUP BY cp.cp_department, d.d_year
)
SELECT department, sales_year, amount, source
FROM sales_data
UNION ALL
SELECT department, sales_year, amount, source
FROM returns_data
ORDER BY sales_year DESC, amount DESC
LIMIT 100
