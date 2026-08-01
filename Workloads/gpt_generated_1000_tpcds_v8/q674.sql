/* Goal: Compare total store sales and returns for each store division and item category for the year 2022, 
   showing detailed rows, subtotals (by division and grand total), limiting to sampled items, 
   and excluding groups with no activity. */
WITH
  sales_agg AS (
    SELECT
      s.s_division_name,
      i.i_category,
      i.i_item_sk,
      SUM(ss.ss_ext_sales_price)      AS total_sales,
      SUM(ss.ss_quantity)              AS total_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY GROUPING SETS (
        (s.s_division_name, i.i_category, i.i_item_sk),
        (s.s_division_name, i.i_category),
        (s.s_division_name),
        ()
    )
  ),

  returns_agg AS (
    SELECT
      s.s_division_name,
      i.i_category,
      i.i_item_sk,
      SUM(sr.sr_return_amt)   AS total_returns,
      SUM(sr.sr_return_quantity) AS total_ret_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY GROUPING SETS (
        (s.s_division_name, i.i_category, i.i_item_sk),
        (s.s_division_name, i.i_category),
        (s.s_division_name),
        ()
    )
  ),

  combined AS (
    SELECT
      s.s_division_name,
      s.i_category,
      s.i_item_sk,
      s.total_sales,
      NULL            AS total_returns,
      s.total_qty,
      NULL            AS total_ret_qty
    FROM sales_agg s
    UNION
    SELECT
      r.s_division_name,
      r.i_category,
      r.i_item_sk,
      NULL            AS total_sales,
      r.total_returns,
      NULL            AS total_qty,
      r.total_ret_qty
    FROM returns_agg r
  ),

  inventory_sample AS (
    SELECT inv_item_sk
    FROM inventory TABLESAMPLE BERNOULLI (10)   -- sample ~10% of inventory rows
  ),

  filtered AS (
    SELECT c.*
    FROM combined c
    JOIN inventory_sample ismp ON c.i_item_sk = ismp.inv_item_sk
    WHERE EXISTS (
      SELECT 1
      FROM store_sales ss2
      JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
      JOIN store s2 ON ss2.ss_store_sk = s2.s_store_sk
      WHERE s2.s_division_name = c.s_division_name
        AND d2.d_year = 2022
    )
  )

SELECT DISTINCT
       f.s_division_name,
       f.i_category,
       COALESCE(f.total_sales, 0)      AS total_sales,
       COALESCE(f.total_returns, 0)    AS total_returns,
       COALESCE(f.total_qty, 0)        AS total_qty,
       COALESCE(f.total_ret_qty, 0)    AS total_ret_qty
FROM filtered f
WHERE f.i_category IN (
        SELECT i2.i_category
        FROM item i2
        WHERE i2.i_class = 'shirts'
      )
EXCEPT
SELECT
       f2.s_division_name,
       f2.i_category,
       f2.total_sales,
       f2.total_returns,
       f2.total_qty,
       f2.total_ret_qty
FROM filtered f2
WHERE f2.total_sales = 0 AND f2.total_returns = 0
ORDER BY total_sales DESC, total_returns ASC
OFFSET 0 LIMIT 100
