WITH
  avg_sales_price AS (
    SELECT avg(ss_ext_sales_price) AS avg_price
    FROM store_sales
  ),
  latest_inventory AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           max(inv_date_sk) AS max_date_sk
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
  )
SELECT
  manager,
  year,
  total_sales,
  sales_category,
  source
FROM (
  -- Sales summary for selected market managers
  SELECT
    s.s_market_manager AS manager,
    d.d_year AS year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    CASE WHEN SUM(ss.ss_ext_sales_price) > (SELECT avg_price FROM avg_sales_price)
         THEN 'Above Avg'
         ELSE 'Below Avg'
    END AS sales_category,
    'Sales' AS source
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE s.s_market_manager IN ('Roger Nichols', 'John Miller')
    AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND EXISTS (
          SELECT 1
          FROM inventory inv
          JOIN latest_inventory li ON inv.inv_item_sk = li.inv_item_sk
                                   AND inv.inv_warehouse_sk = li.inv_warehouse_sk
                                   AND inv.inv_date_sk = li.max_date_sk
          WHERE inv.inv_item_sk = ss.ss_item_sk
            AND inv.inv_quantity_on_hand > 0
        )
  GROUP BY s.s_market_manager, d.d_year

  UNION ALL

  -- Inventory summary for selected warehouse cities
  SELECT
    w.w_city AS manager,
    d.d_year AS year,
    SUM(inv.inv_quantity_on_hand) AS total_sales,
    CASE WHEN SUM(inv.inv_quantity_on_hand) > 1000
         THEN 'High Stock'
         ELSE 'Low Stock'
    END AS sales_category,
    'Inventory' AS source
  FROM inventory inv
  JOIN latest_inventory li ON inv.inv_item_sk = li.inv_item_sk
                           AND inv.inv_warehouse_sk = li.inv_warehouse_sk
                           AND inv.inv_date_sk = li.max_date_sk
  JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE w.w_city IN ('Fairview', 'Riverside')
    AND d.d_year = 2001
  GROUP BY w.w_city, d.d_year
) AS combined
ORDER BY manager, year DESC, source
OFFSET 0
LIMIT 100
