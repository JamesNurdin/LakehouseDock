WITH ss AS (
  SELECT d.d_year AS d_year,
         s.s_state AS region,
         i.i_category AS category,
         SUM(ss.ss_net_paid) AS total_sales,
         SUM(ss.ss_net_profit) AS total_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, s.s_state, i.i_category
), cs AS (
  SELECT d.d_year AS d_year,
         'Catalog' AS region,
         i.i_category AS category,
         SUM(cs.cs_net_paid) AS total_sales,
         SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category
), ws AS (
  SELECT d.d_year AS d_year,
         'Web' AS region,
         i.i_category AS category,
         SUM(ws.ws_net_paid) AS total_sales,
         SUM(ws.ws_net_profit) AS total_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category
)
SELECT d_year, region, category, total_sales, total_profit
FROM (
  SELECT d_year, region, category, total_sales, total_profit FROM ss
  UNION ALL
  SELECT d_year, region, category, total_sales, total_profit FROM cs
  UNION ALL
  SELECT d_year, region, category, total_sales, total_profit FROM ws
) t
WHERE total_sales > 1000000
ORDER BY total_sales DESC
LIMIT 200
