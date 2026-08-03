WITH
  sales_summary AS (
    SELECT
      i.i_category AS category,
      d.d_year AS year,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY ROLLUP (i.i_category, d.d_year)
  ),
  inventory_summary AS (
    SELECT
      i.i_category AS category,
      d.d_year AS year,
      SUM(inv.inv_quantity_on_hand) AS total_quantity,
      COUNT(DISTINCT inv.inv_warehouse_sk) AS distinct_warehouses
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY ROLLUP (i.i_category, d.d_year)
  ),
  sales_keys AS (
    SELECT DISTINCT i.i_category AS category
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
  ),
  inventory_keys AS (
    SELECT DISTINCT i.i_category AS category
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
  ),
  category_excess AS (
    SELECT category FROM sales_keys
    EXCEPT
    SELECT category FROM inventory_keys
  ),
  category_common AS (
    SELECT category FROM sales_keys
    INTERSECT
    SELECT category FROM inventory_keys
  ),
  full_join_summary AS (
    SELECT
      COALESCE(s.category, i.category) AS category,
      COALESCE(s.year, i.year) AS year,
      s.total_sales,
      s.distinct_customers,
      s.distinct_tickets,
      i.total_quantity,
      i.distinct_warehouses
    FROM sales_summary s
    FULL OUTER JOIN inventory_summary i
      ON s.category = i.category AND s.year = i.year
  )
SELECT
  category,
  year,
  total_sales,
  distinct_customers,
  distinct_tickets,
  total_quantity,
  distinct_warehouses
FROM full_join_summary
UNION ALL
SELECT
  category,
  NULL AS year,
  NULL AS total_sales,
  NULL AS distinct_customers,
  NULL AS distinct_tickets,
  NULL AS total_quantity,
  NULL AS distinct_warehouses
FROM category_excess
UNION ALL
SELECT
  category,
  NULL AS year,
  NULL AS total_sales,
  NULL AS distinct_customers,
  NULL AS distinct_tickets,
  NULL AS total_quantity,
  NULL AS distinct_warehouses
FROM category_common
LIMIT 100
