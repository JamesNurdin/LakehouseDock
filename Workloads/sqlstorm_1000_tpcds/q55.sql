WITH unified_sales AS (
    SELECT d.d_year,
           i.i_category,
           'catalog' AS channel,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           i.i_category,
           'store' AS channel,
           ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           i.i_category,
           'web' AS channel,
           ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
aggregated AS (
    SELECT d_year,
           i_category,
           channel,
           SUM(profit) AS total_profit
    FROM unified_sales
    GROUP BY d_year, i_category, channel
),
ranked AS (
    SELECT d_year,
           i_category,
           channel,
           total_profit,
           ROW_NUMBER() OVER (PARTITION BY d_year, i_category ORDER BY total_profit DESC) AS rn
    FROM aggregated
)
SELECT d_year,
       i_category,
       channel,
       total_profit
FROM ranked
WHERE rn <= 5
ORDER BY d_year, i_category, total_profit DESC
