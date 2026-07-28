WITH catalog_monthly AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           'Catalog' AS channel
    FROM tpcds.catalog_sales AS cs
    INNER JOIN tpcds.date_dim AS d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
web_monthly AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           'Web' AS channel
    FROM tpcds.web_sales AS ws
    INNER JOIN tpcds.date_dim AS d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
)
SELECT year,
       month_seq,
       total_sales,
       channel
FROM catalog_monthly
UNION ALL
SELECT year,
       month_seq,
       total_sales,
       channel
FROM web_monthly
ORDER BY year,
         month_seq,
         channel
LIMIT 100
