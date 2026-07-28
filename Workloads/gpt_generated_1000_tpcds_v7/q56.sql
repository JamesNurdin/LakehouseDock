WITH store_profit AS (
   SELECT
       s.s_state AS state,
       'Store' AS channel,
       SUM(ss.ss_net_profit) AS total_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE d.d_year = 2002
   GROUP BY s.s_state
),
catalog_profit AS (
   SELECT
       cc.cc_state AS state,
       'Catalog' AS channel,
       SUM(cs.cs_net_profit) AS total_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE d.d_year = 2002
   GROUP BY cc.cc_state
)
SELECT state, channel, total_profit
FROM store_profit
UNION ALL
SELECT state, channel, total_profit
FROM catalog_profit
ORDER BY total_profit DESC
LIMIT 100
