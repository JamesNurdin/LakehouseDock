WITH max_profit AS (
   SELECT MAX(ws.ws_net_paid_inc_ship) AS max_profit
   FROM tpcds.web_sales ws
),
sub1 AS (
   SELECT
       d.d_year,
       sm.sm_type,
       SUM(ws.ws_net_paid_inc_ship) AS total_sales,
       CASE WHEN SUM(ws.ws_net_paid_inc_ship) > 20000 THEN 'High' ELSE 'Low' END AS sales_category,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_paid_inc_ship) DESC) AS sales_rank
   FROM tpcds.web_sales ws
   TABLESAMPLE BERNOULLI (10)
   JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2022
     AND ws.ws_net_paid_inc_ship > (SELECT max_profit FROM max_profit)
   GROUP BY d.d_year, sm.sm_type
   HAVING SUM(ws.ws_net_paid_inc_ship) > 10000
),
sub2 AS (
   SELECT
       d.d_year,
       sm.sm_type,
       SUM(ws.ws_net_paid_inc_ship) AS total_sales,
       CASE WHEN SUM(ws.ws_net_paid_inc_ship) > 25000 THEN 'High' ELSE 'Low' END AS sales_category,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_paid_inc_ship) DESC) AS sales_rank
   FROM tpcds.web_sales ws
   TABLESAMPLE BERNOULLI (10)
   JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2023
     AND ws.ws_net_paid_inc_ship > (SELECT max_profit FROM max_profit)
   GROUP BY d.d_year, sm.sm_type
   HAVING SUM(ws.ws_net_paid_inc_ship) > 12000
)
SELECT *
FROM sub1
UNION ALL
SELECT *
FROM sub2
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
