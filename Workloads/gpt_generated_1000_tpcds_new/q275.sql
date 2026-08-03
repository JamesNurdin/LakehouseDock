WITH store_data AS (
    SELECT
        d.d_date,
        ss.ss_ext_sales_price AS sales_amount,
        'Store' AS sales_channel,
        ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY ss.ss_ext_sales_price DESC) AS sales_rank
    FROM store_sales ss
    FULL OUTER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ss.ss_quantity > 0
),
catalog_data AS (
    SELECT
        d.d_date,
        cs.cs_ext_sales_price AS sales_amount,
        'Catalog' AS sales_channel,
        ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank
    FROM catalog_sales cs
    FULL OUTER JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_quantity > 0
)
SELECT
    combined.d_date,
    combined.sales_amount,
    combined.sales_channel,
    combined.sales_rank,
    CASE WHEN combined.sales_amount > 1000 THEN 'High' ELSE 'Low' END AS sales_category
FROM (
    SELECT d_date, sales_amount, sales_channel, sales_rank FROM store_data
    UNION
    SELECT d_date, sales_amount, sales_channel, sales_rank FROM catalog_data
) AS combined
ORDER BY combined.d_date DESC, combined.sales_amount DESC
LIMIT 100
