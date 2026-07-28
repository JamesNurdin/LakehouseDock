WITH catalog_agg AS (
   SELECT
       d.d_year AS year,
       i.i_category AS category,
       SUM(cs.cs_net_paid) AS total_net_paid,
       SUM(cs.cs_quantity) AS total_quantity
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY ROLLUP (d.d_year, i.i_category)
),
catalog_ranked AS (
   SELECT
       'catalog' AS sales_channel,
       year,
       category,
       total_net_paid,
       total_quantity,
       ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_paid DESC) AS category_rank
   FROM catalog_agg
),
web_agg AS (
   SELECT
       d.d_year AS year,
       i.i_category AS category,
       SUM(ws.ws_net_paid) AS total_net_paid,
       SUM(ws.ws_quantity) AS total_quantity
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY ROLLUP (d.d_year, i.i_category)
),
web_ranked AS (
   SELECT
       'web' AS sales_channel,
       year,
       category,
       total_net_paid,
       total_quantity,
       ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_paid DESC) AS category_rank
   FROM web_agg
)
SELECT *
FROM catalog_ranked
UNION ALL
SELECT *
FROM web_ranked
ORDER BY sales_channel, year, category_rank
LIMIT 100
