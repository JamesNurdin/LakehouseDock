WITH store_sales_agg AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           SUM(ss.ss_net_profit) AS net_profit,
           SUM(ss.ss_net_paid) AS revenue
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
), catalog_sales_agg AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           SUM(cs.cs_net_profit) AS net_profit,
           SUM(cs.cs_net_paid) AS revenue
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
), web_sales_agg AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           SUM(ws.ws_net_profit) AS net_profit,
           SUM(ws.ws_net_paid) AS revenue
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
)
SELECT
    year,
    category,
    SUM(net_profit) AS total_net_profit,
    SUM(revenue) AS total_revenue
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
) t
GROUP BY year, category
ORDER BY year, total_net_profit DESC
