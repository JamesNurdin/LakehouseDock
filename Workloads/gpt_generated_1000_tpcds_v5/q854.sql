WITH profit_2020 AS (
   SELECT
       sm.sm_carrier AS carrier,
       d.d_year AS year,
       SUM(cs.cs_net_profit) AS total_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2020
     AND sm.sm_carrier = 'UPS'
   GROUP BY sm.sm_carrier, d.d_year
),
profit_2021 AS (
   SELECT
       sm.sm_carrier AS carrier,
       d.d_year AS year,
       SUM(cs.cs_net_profit) AS total_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2021
     AND sm.sm_carrier = 'ZOUROS'
   GROUP BY sm.sm_carrier, d.d_year
)
SELECT carrier, year, total_profit
FROM profit_2020
UNION ALL
SELECT carrier, year, total_profit
FROM profit_2021
ORDER BY total_profit DESC
LIMIT 100
