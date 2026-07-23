WITH catalog_agg AS (
    SELECT d.d_year AS year,
           'catalog' AS source,
           SUM(cs.cs_net_paid) AS total_net_paid,
           SUM(cs.cs_net_profit) AS total_net_profit,
           CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
),
store_agg AS (
    SELECT d.d_year AS year,
           'store' AS source,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_net_profit) AS total_net_profit,
           CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
)
SELECT year,
       source,
       total_net_paid,
       total_net_profit,
       profit_status
FROM catalog_agg
UNION ALL
SELECT year,
       source,
       total_net_paid,
       total_net_profit,
       profit_status
FROM store_agg
ORDER BY year, source
LIMIT 100
