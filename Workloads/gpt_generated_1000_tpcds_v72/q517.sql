WITH
  store_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS sales_transactions,
      CASE
        WHEN SUM(ss.ss_net_paid) > (
          SELECT AVG(day_total) FROM (
            SELECT SUM(ss2.ss_net_paid) AS day_total
            FROM store_sales ss2
            JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
            GROUP BY d2.d_date_sk
          ) t
        ) THEN 'Above Avg' ELSE 'Below Avg'
      END AS performance_bucket
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_category IN ('Sports', 'Books')
      AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = ss.ss_item_sk
          AND inv.inv_quantity_on_hand > 500
      )
    GROUP BY d.d_year, i.i_category
  ),
  catalog_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      SUM(cs.cs_net_paid) AS total_net_paid,
      COUNT(*) AS sales_transactions,
      CASE
        WHEN SUM(cs.cs_net_paid) > (
          SELECT AVG(day_total) FROM (
            SELECT SUM(cs2.cs_net_paid) AS day_total
            FROM catalog_sales cs2
            JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
            GROUP BY d2.d_date_sk
          ) t
        ) THEN 'Above Avg' ELSE 'Below Avg'
      END AS performance_bucket
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_category = 'Sports'
      AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = cs.cs_item_sk
          AND inv.inv_quantity_on_hand > 500
      )
    GROUP BY d.d_year, i.i_category
  )
SELECT year,
       category,
       total_net_paid,
       sales_transactions,
       performance_bucket
FROM   store_agg
UNION ALL
SELECT year,
       category,
       total_net_paid,
       sales_transactions,
       performance_bucket
FROM   catalog_agg
ORDER BY year,
         total_net_paid DESC
LIMIT 100
