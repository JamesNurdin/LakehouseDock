WITH
  -- Scalar subquery returning the overall average quantity on hand
  avg_qty AS (
    SELECT AVG(inv_quantity_on_hand) AS avg_quantity FROM inventory
  ),
  -- Remove duplicate inventory rows (if any) before joining
  distinct_inventory AS (
    SELECT DISTINCT
      inv_item_sk,
      inv_date_sk,
      inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 500
  )
SELECT
  d.d_date,
  s.s_store_id,
  s.s_city,
  cp.cp_catalog_page_id,
  SUM(di.inv_quantity_on_hand) AS total_qty_on_hand,
  COUNT(DISTINCT di.inv_item_sk) AS distinct_items,
  AVG(CASE WHEN di.inv_quantity_on_hand > (SELECT avg_quantity FROM avg_qty) THEN di.inv_quantity_on_hand END) AS avg_above_avg_qty,
  CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_category
FROM date_dim d
FULL OUTER JOIN distinct_inventory di ON di.inv_date_sk = d.d_date_sk
INNER JOIN store s ON s.s_closed_date_sk = d.d_date_sk
INNER JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
WHERE
  s.s_country = 'United States'
  AND s.s_city = 'Spring Valley'
  AND cp.cp_department = 'Electronics'
GROUP BY
  d.d_date,
  s.s_store_id,
  s.s_city,
  cp.cp_catalog_page_id,
  s.s_state
ORDER BY total_qty_on_hand DESC
LIMIT 100
