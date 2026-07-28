WITH filtered_inventory AS (
    SELECT i.inv_date_sk,
           i.inv_item_sk,
           i.inv_warehouse_sk,
           i.inv_quantity_on_hand,
           d.d_year,
           d.d_weekend,
           d.d_same_day_ly
    FROM inventory i
    JOIN date_dim d
      ON i.inv_date_sk = d.d_date_sk
    WHERE i.inv_quantity_on_hand > 0
      AND i.inv_warehouse_sk IN (3, 6, 9)
      AND d.d_weekend = 'N'
      AND d.d_year = 2001
      AND d.d_same_day_ly = 2414666
) 
SELECT cp.cp_catalog_page_id,
       cp.cp_department,
       cp.cp_type,
       fi.d_year,
       fi.inv_warehouse_sk,
       SUM(fi.inv_quantity_on_hand) AS total_quantity,
       CASE WHEN SUM(fi.inv_quantity_on_hand) > 1000 THEN 'High' ELSE 'Low' END AS quantity_category,
       RANK() OVER (PARTITION BY fi.d_year ORDER BY SUM(fi.inv_quantity_on_hand) DESC) AS qty_rank,
       SUM(SUM(fi.inv_quantity_on_hand)) OVER (
           PARTITION BY fi.d_year 
           ORDER BY SUM(fi.inv_quantity_on_hand) DESC 
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative_qty
FROM filtered_inventory fi
JOIN catalog_page cp
  ON cp.cp_start_date_sk = fi.inv_date_sk
WHERE cp.cp_catalog_number > 5
  AND cp.cp_department IS NOT NULL
GROUP BY cp.cp_catalog_page_id,
         cp.cp_department,
         cp.cp_type,
         fi.d_year,
         fi.inv_warehouse_sk
HAVING SUM(fi.inv_quantity_on_hand) > 500
ORDER BY total_quantity DESC, qty_rank
LIMIT 100
