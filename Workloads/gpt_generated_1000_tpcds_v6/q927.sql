WITH sold_sales AS (
    SELECT
        d.d_year AS year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS transaction_cnt
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cs.cs_quantity > 1
    GROUP BY d.d_year
),
ship_sales AS (
    SELECT
        d.d_year AS year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS transaction_cnt
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_ship_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cs.cs_quantity > 1
    GROUP BY d.d_year
)
SELECT
    year,
    total_sales,
    total_profit,
    transaction_cnt,
    'sold' AS sales_type
FROM sold_sales
UNION ALL
SELECT
    year,
    total_sales,
    total_profit,
    transaction_cnt,
    'ship' AS sales_type
FROM ship_sales
ORDER BY year, sales_type
