WITH store AS (
   SELECT
       'store' AS sales_type,
       i.i_category AS category,
       d.d_month_seq AS month_seq,
       SUM(ss.ss_net_profit) AS net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY GROUPING SETS (
       (i.i_category, d.d_month_seq),
       (i.i_category),
       (d.d_month_seq)
   )
),
catalog AS (
   SELECT
       'catalog' AS sales_type,
       i.i_category AS category,
       d.d_month_seq AS month_seq,
       SUM(cs.cs_net_profit) AS net_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY GROUPING SETS (
       (i.i_category, d.d_month_seq),
       (i.i_category),
       (d.d_month_seq)
   )
)
SELECT sales_type, category, month_seq, net_profit
FROM store
UNION ALL
SELECT sales_type, category, month_seq, net_profit
FROM catalog
ORDER BY sales_type, category, month_seq
LIMIT 100
