WITH catalog_monthly AS (
   SELECT
      d.d_moy AS month,
      'catalog' AS channel,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2001
     AND sm.sm_type = 'AIR'
   GROUP BY d.d_moy
),
web_monthly AS (
   SELECT
      d.d_moy AS month,
      'web' AS channel,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2001
     AND sm.sm_type = 'AIR'
   GROUP BY d.d_moy
),
combined AS (
   SELECT * FROM catalog_monthly
   UNION ALL
   SELECT * FROM web_monthly
)
SELECT
   c.month,
   c.channel,
   c.total_profit,
   c.distinct_customers
FROM combined c
WHERE c.total_profit > (
   SELECT avg_profit * 1.2
   FROM (
       SELECT AVG(cs.cs_net_profit) AS avg_profit
       FROM catalog_sales cs
       JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
       WHERE d.d_year = 2001
   ) avg_sub
)
ORDER BY c.month, c.channel
LIMIT 100
