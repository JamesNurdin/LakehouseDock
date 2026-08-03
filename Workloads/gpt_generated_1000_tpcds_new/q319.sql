/*
  Goal: Compute a combined profitability metric per warehouse by first summarizing sales and returns, then averaging profits, unioning the two result sets, and finally aggregating the union. The query demonstrates:
  • Star‑join of the fact table catalog_sales to warehouse, catalog_returns (FULL OUTER JOIN) and inventory via a LATERAL subquery on warehouse.
  • Two CTEs with different aggregations (SUM and AVG).
  • UNION DISTINCT of those aggregates.
  • A second aggregation with HAVING, ORDER BY and LIMIT.
*/
WITH
  -- Inventory per warehouse (using a LATERAL subquery)
  warehouse_stock AS (
    SELECT
      w.w_warehouse_sk,
      w.w_warehouse_name,
      w.w_warehouse_sq_ft,
      w.w_county,
      lst.total_stock
    FROM
      warehouse w
      CROSS JOIN LATERAL (
        SELECT COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_stock
        FROM inventory inv
        WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
      ) lst
    WHERE
      w.w_warehouse_sq_ft > 200000                -- predicate 1
      AND w.w_county IN ('Ziebach County', 'Marshall County')  -- predicate 2
  ),

  -- Sales joined to returns (FULL OUTER) and to warehouse + its stock
  base_sales_returns AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_warehouse_sk,
      cs.cs_ext_tax,
      cs.cs_net_profit,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      ws.total_stock,
      w.w_warehouse_name,
      w.w_warehouse_sq_ft
    FROM
      catalog_sales cs
      JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
      FULL OUTER JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
      JOIN warehouse_stock ws ON w.w_warehouse_sk = ws.w_warehouse_sk
    WHERE
      cs.cs_ext_tax BETWEEN 20 AND 100            -- predicate 3
      AND cs.cs_warehouse_sk IN (4, 8, 18)          -- predicate 4
      AND (cr.cr_return_quantity IS NULL OR cr.cr_return_quantity > 0)  -- predicate 5
  ),

  -- First aggregation: summed metrics per warehouse
  agg_sum AS (
    SELECT
      w_warehouse_name,
      SUM(cs_net_profit) AS total_profit,
      SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
      SUM(cs_ext_tax) AS total_tax,
      SUM(total_stock) AS summed_stock
    FROM
      base_sales_returns
    GROUP BY
      w_warehouse_name
  ),

  -- Second aggregation: average metrics per warehouse
  agg_avg AS (
    SELECT
      w_warehouse_name,
      AVG(cs_net_profit) AS avg_profit,
      AVG(total_stock) AS avg_stock
    FROM
      base_sales_returns
    GROUP BY
      w_warehouse_name
  ),

  -- Union the two aggregates (distinct rows only)
  union_agg AS (
    SELECT w_warehouse_name, total_profit AS metric FROM agg_sum
    UNION
    SELECT w_warehouse_name, avg_profit   AS metric FROM agg_avg
  )

SELECT
  u.w_warehouse_name,
  SUM(u.metric) AS combined_metric
FROM
  union_agg u
GROUP BY
  u.w_warehouse_name
HAVING
  SUM(u.metric) > 1000                -- final filter on the combined metric
ORDER BY
  combined_metric DESC
LIMIT 100
