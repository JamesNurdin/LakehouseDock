WITH combined_sales AS (
    SELECT d.d_date AS sales_date,
           ss.ss_net_paid AS net_paid,
           'store' AS sales_source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
    UNION ALL
    SELECT d.d_date AS sales_date,
           cs.cs_net_paid AS net_paid,
           'catalog' AS sales_source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
)
SELECT sales_date,
       sales_source,
       SUM(net_paid) AS total_net_paid
FROM combined_sales
GROUP BY sales_date, sales_source
ORDER BY sales_date
