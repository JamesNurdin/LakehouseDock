WITH store_profit AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
    HAVING SUM(ss.ss_net_profit) > (
        SELECT AVG(ss2.ss_net_profit) * 1.5
        FROM store_sales ss2
    )
),
catalog_profit AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
    HAVING SUM(cs.cs_net_profit) > (
        SELECT AVG(cs2.cs_net_profit) * 1.5
        FROM catalog_sales cs2
    )
)
SELECT year,
       category,
       total_profit,
       'store'   AS source
FROM   store_profit
WHERE  total_profit > 0
UNION ALL
SELECT year,
       category,
       total_profit,
       'catalog' AS source
FROM   catalog_profit
WHERE  total_profit > 0
ORDER BY year DESC,
         total_profit DESC
LIMIT 100
