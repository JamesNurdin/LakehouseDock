WITH
  returns_agg AS (
    SELECT
      w.w_warehouse_name,
      i.i_category,
      SUM(cr.cr_return_amount) AS total_amount,
      'return' AS source,
      GROUPING(w.w_warehouse_name) AS g_warehouse,
      GROUPING(i.i_category) AS g_category
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 0
    GROUP BY GROUPING SETS (
      (w.w_warehouse_name, i.i_category),
      (w.w_warehouse_name),
      ()
    )
  ),
  sales_agg AS (
    SELECT
      w.w_warehouse_name,
      i.i_category,
      SUM(cs.cs_net_paid) AS total_amount,
      'sale' AS source,
      GROUPING(w.w_warehouse_name) AS g_warehouse,
      GROUPING(i.i_category) AS g_category
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_net_paid > 0
    GROUP BY GROUPING SETS (
      (w.w_warehouse_name, i.i_category),
      (w.w_warehouse_name),
      ()
    )
  )
SELECT
  source,
  COALESCE(w_warehouse_name, 'All Warehouses') AS warehouse,
  COALESCE(i_category, 'All Categories') AS category,
  total_amount,
  ROW_NUMBER() OVER (PARTITION BY source, w_warehouse_name ORDER BY total_amount DESC) AS rank_within_warehouse
FROM (
  SELECT * FROM returns_agg
  UNION ALL
  SELECT * FROM sales_agg
) u
ORDER BY source, warehouse, rank_within_warehouse
LIMIT 100
