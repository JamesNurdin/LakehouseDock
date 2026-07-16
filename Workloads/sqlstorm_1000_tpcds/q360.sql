WITH catalog_fact AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
), store_fact AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
), web_fact AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
), combined AS (
    SELECT year,
           category,
           profit AS catalog_profit,
           0.0 AS store_profit,
           0.0 AS web_profit
    FROM catalog_fact
    UNION ALL
    SELECT year,
           category,
           0.0,
           profit,
           0.0
    FROM store_fact
    UNION ALL
    SELECT year,
           category,
           0.0,
           0.0,
           profit
    FROM web_fact
)
SELECT year,
       category,
       sum(catalog_profit) AS catalog_net_profit,
       sum(store_profit) AS store_net_profit,
       sum(web_profit) AS web_net_profit,
       sum(catalog_profit + store_profit + web_profit) AS total_net_profit
FROM combined
GROUP BY year, category
ORDER BY year, total_net_profit DESC
LIMIT 100
