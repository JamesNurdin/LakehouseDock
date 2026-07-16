WITH sales AS (
    SELECT d.d_year,
           i.i_brand,
           i.i_category,
           'store' AS channel,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           i.i_brand,
           i.i_category,
           'catalog' AS channel,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           i.i_brand,
           i.i_category,
           'web' AS channel,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
), aggregated AS (
    SELECT d_year,
           channel,
           i_brand,
           i_category,
           sum(net_paid) AS total_net_paid,
           sum(net_profit) AS total_net_profit
    FROM sales
    WHERE d_year BETWEEN 1998 AND 2002
    GROUP BY d_year, channel, i_brand, i_category
), ranked AS (
    SELECT *,
           row_number() OVER (PARTITION BY d_year, channel ORDER BY total_net_paid DESC) AS brand_rank
    FROM aggregated
)
SELECT d_year,
       channel,
       i_brand,
       i_category,
       total_net_paid,
       total_net_profit
FROM ranked
WHERE brand_rank <= 10
ORDER BY d_year, channel, brand_rank
