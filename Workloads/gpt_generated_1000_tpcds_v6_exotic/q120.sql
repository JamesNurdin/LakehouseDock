WITH catalog AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, i.i_category
),
web AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           -SUM(ws.ws_net_profit) AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, i.i_category
)
SELECT
    year,
    category,
    SUM(profit) AS total_profit
FROM (
    SELECT year, category, profit FROM catalog
    UNION ALL
    SELECT year, category, profit FROM web
) t
GROUP BY GROUPING SETS ((year, category), (year), ())
ORDER BY total_profit DESC
LIMIT 100
