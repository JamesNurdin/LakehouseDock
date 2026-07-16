WITH sales_union AS (
    SELECT d.d_year AS year,
           s.s_state AS state,
           i.i_category AS category,
           ss.ss_net_profit AS profit,
           1 AS cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT d.d_year,
           cc.cc_state,
           i.i_category,
           cs.cs_net_profit,
           1
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT d.d_year,
           w.web_state,
           i.i_category,
           ws.ws_net_profit,
           1
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
),
agg AS (
    SELECT year,
           state,
           category,
           SUM(profit) AS total_profit,
           SUM(cnt) AS total_sales
    FROM sales_union
    GROUP BY year, state, category
)
SELECT
    year,
    state,
    category,
    total_profit,
    total_sales,
    RANK() OVER (PARTITION BY year ORDER BY total_profit DESC) AS profit_rank,
    ROUND(total_profit / SUM(total_profit) OVER (PARTITION BY year), 4) AS profit_share,
    ROUND(AVG(total_profit) OVER (PARTITION BY state ORDER BY year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS profit_3yr_moving_avg
FROM agg
WHERE category IS NOT NULL
ORDER BY year, profit_rank
LIMIT 200
