WITH
  -- average sales price per item for the year 2001 (scalar subquery used later)
  avg_price AS (
    SELECT i.i_item_sk,
           AVG(ss.ss_ext_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk
  ),

  -- rank items by total sales within each store for 2001
  sales_rank AS (
    SELECT s.s_store_id,
           i.i_item_id,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, i.i_item_id
    HAVING SUM(ss.ss_ext_sales_price) > (
      SELECT AVG(t.store_sales)
      FROM (
        SELECT SUM(ss2.ss_ext_sales_price) AS store_sales
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
        GROUP BY ss2.ss_store_sk
      ) t
    )
  ),

  -- inventory snapshot for 2001 where quantity on hand is high
  inventory_snapshot AS (
    SELECT s.s_store_id,
           i.i_item_id,
           inv.inv_quantity_on_hand,
           d.d_date
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND inv.inv_quantity_on_hand > 500
  )

SELECT DISTINCT
  combined.store_id,
  combined.item_id,
  combined.metric,
  combined.source
FROM (
  -- top‑3 selling items per store
  SELECT sr.s_store_id AS store_id,
         sr.i_item_id AS item_id,
         sr.total_sales AS metric,
         'sales' AS source
  FROM sales_rank sr
  WHERE sr.sales_rank <= 3

  UNION ALL

  -- inventory levels for the same year
  SELECT isnap.s_store_id AS store_id,
         isnap.i_item_id AS item_id,
         isnap.inv_quantity_on_hand AS metric,
         'inventory' AS source
  FROM inventory_snapshot isnap
) AS combined
ORDER BY combined.store_id, combined.metric DESC
