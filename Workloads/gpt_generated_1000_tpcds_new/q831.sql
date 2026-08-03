WITH
  sales_items AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_warehouse_sk,
      SUM(cs.cs_net_profit) AS total_profit,
      CASE
        WHEN SUM(cs.cs_net_profit) > 100000 THEN 'High'
        WHEN SUM(cs.cs_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
      END AS profit_category
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city IN ('Greenwood', 'Pleasant Valley')
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk
    HAVING SUM(cs.cs_quantity) > 100
  ),
  inventory_items AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      inv.inv_warehouse_sk,
      inv.inv_quantity_on_hand,
      CASE
        WHEN inv.inv_quantity_on_hand > 500 THEN 'Plenty'
        WHEN inv.inv_quantity_on_hand > 100 THEN 'Moderate'
        ELSE 'Low'
      END AS stock_level
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
  ),
  expanded_warehouses AS (
    SELECT
      w.w_warehouse_sk,
      w.w_city,
      city_part
    FROM warehouse w
    CROSS JOIN UNNEST(array[w.w_city]) AS t(city_part)
  )
SELECT si.cs_item_sk AS item_key
FROM sales_items si
WHERE EXISTS (
        SELECT 1
        FROM expanded_warehouses ew
        WHERE ew.w_warehouse_sk = si.cs_warehouse_sk
          AND ew.city_part LIKE '%wood%'
      )
INTERSECT
SELECT ii.i_item_sk AS item_key
FROM inventory_items ii
WHERE ii.stock_level = 'Plenty'
LIMIT 100
