WITH store_agg AS (
   SELECT
      d.d_year AS d_year,
      i.i_category AS i_category,
      SUM(ss.ss_net_paid) AS net_paid,
      SUM(ss.ss_quantity) AS units,
      'store' AS sales_channel
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   GROUP BY d.d_year, i.i_category
),
catalog_agg AS (
   SELECT
      d.d_year AS d_year,
      i.i_category AS i_category,
      SUM(cs.cs_net_paid) AS net_paid,
      SUM(cs.cs_quantity) AS units,
      'catalog' AS sales_channel
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   GROUP BY d.d_year, i.i_category
),
combined AS (
   SELECT * FROM store_agg
   UNION ALL
   SELECT * FROM catalog_agg
)
SELECT
   c.d_year,
   c.i_category,
   c.sales_channel,
   c.net_paid,
   c.units,
   RANK() OVER (PARTITION BY c.d_year ORDER BY c.net_paid DESC) AS sales_rank
FROM combined c
WHERE c.d_year BETWEEN 2001 AND 2002
ORDER BY c.d_year, sales_rank
LIMIT 100
