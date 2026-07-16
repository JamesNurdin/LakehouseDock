WITH unified_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_profit AS net_profit,
           cc.cc_state AS state
    FROM catalog_sales cs
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    UNION ALL
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_profit AS net_profit,
           s.s_state AS state
    FROM store_sales ss
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_profit AS net_profit,
           w.web_state AS state
    FROM web_sales ws
    LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
),
aggregated_sales AS (
    SELECT d.d_year,
           us.state,
           SUM(us.quantity) AS total_quantity,
           SUM(us.net_profit) AS total_profit
    FROM unified_sales us
    JOIN date_dim d ON us.date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, us.state
)
SELECT d_year,
       state,
       total_quantity,
       total_profit,
       ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM aggregated_sales
ORDER BY d_year, profit_rank
