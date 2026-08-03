WITH sales_union AS (
    SELECT d.d_year AS year,
           d.d_moy   AS month,
           'Catalog' AS source,
           SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, d.d_moy
    UNION ALL
    SELECT d.d_year AS year,
           d.d_moy   AS month,
           'Store'   AS source,
           SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, d.d_moy
)
SELECT 
    year,
    month,
    source,
    SUM(total_net_paid) AS total_net_paid,
    CASE WHEN SUM(total_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS sales_category
FROM sales_union
GROUP BY year, month, source
HAVING SUM(total_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
