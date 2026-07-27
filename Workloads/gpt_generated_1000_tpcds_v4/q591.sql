WITH catalog_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        'catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY d.d_year, d.d_month_seq
),
store_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        'store' AS channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    combined.year,
    combined.month_seq,
    combined.channel,
    combined.total_sales,
    combined.orders,
    ROW_NUMBER() OVER (PARTITION BY combined.year ORDER BY combined.total_sales DESC) AS sales_rank
FROM (
    SELECT year, month_seq, channel, total_sales, orders FROM catalog_monthly
    UNION ALL
    SELECT year, month_seq, channel, total_sales, orders FROM store_monthly
) AS combined
ORDER BY combined.year, combined.month_seq, sales_rank
LIMIT 100
