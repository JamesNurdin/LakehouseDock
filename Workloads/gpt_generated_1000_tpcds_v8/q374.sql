/*
  Goal: Compare daily sales from the store channel and the catalog channel for overlapping product categories in the year 2001.
  Show subtotals by store and category using GROUPING SETS, compute the previous day's sales and a running total per store,
  and remove any catalog‑sales rows with a negative total.
*/
WITH
  -- Aggregate sales from the Store Sales fact table
  store_agg AS (
    SELECT
      s.s_store_id        AS store_id,
      i.i_category        AS category,
      d.d_date            AS sale_date,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      'store'             AS src
    FROM store_sales ss
    JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s           ON ss.ss_store_sk = s.s_store_sk
    JOIN item i            ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY s.s_store_id, i.i_category, d.d_date
  ),

  -- Aggregate sales from the Catalog Sales fact table
  catalog_agg AS (
    SELECT
      CAST(NULL AS VARCHAR) AS store_id,
      i.i_category          AS category,
      d.d_date              AS sale_date,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      'catalog'             AS src
    FROM catalog_sales cs
    JOIN date_dim d      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i          ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY i.i_category, d.d_date
  ),

  -- Intersection of the key sets (category + date) that appear in BOTH channels
  intersect_keys AS (
    SELECT category, sale_date FROM store_agg
    INTERSECT
    SELECT category, sale_date FROM catalog_agg
  ),

  -- Union the two aggregated streams
  combined AS (
    SELECT store_id, category, sale_date, total_sales, src FROM store_agg
    UNION ALL
    SELECT store_id, category, sale_date, total_sales, src FROM catalog_agg
  ),

  -- Keep only rows that belong to the intersected key set
  filtered AS (
    SELECT c.*
    FROM combined c
    WHERE (c.category, c.sale_date) IN (SELECT category, sale_date FROM intersect_keys)
  ),

  -- Exclude negative catalog‑sales rows using EXCEPT
  filtered_except AS (
    SELECT store_id, category, sale_date, total_sales, src FROM filtered
    EXCEPT
    SELECT store_id, category, sale_date, total_sales, src FROM filtered
    WHERE src = 'catalog' AND total_sales < 0
  ),

  -- Produce subtotals with GROUPING SETS
  aggregated AS (
    SELECT
      store_id,
      category,
      sale_date,
      src,
      SUM(total_sales) AS total_sales
    FROM filtered_except
    GROUP BY GROUPING SETS (
      (store_id, category, sale_date, src),   -- detailed rows
      (store_id, category, src),              -- subtotal per store & category
      (store_id, src),                        -- subtotal per store
      (src)                                   -- grand total per source
    )
  )
SELECT
  store_id,
  category,
  sale_date,
  src,
  total_sales,
  LAG(total_sales) OVER (PARTITION BY store_id ORDER BY sale_date) AS prev_day_sales,
  SUM(total_sales) OVER (PARTITION BY store_id ORDER BY sale_date
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM aggregated
ORDER BY store_id, category, sale_date
LIMIT 100
