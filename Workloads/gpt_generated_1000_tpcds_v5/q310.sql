WITH agg_inventory AS (
  SELECT
    i.i_item_sk,
    i.i_brand,
    w.w_warehouse_sk,
    w.w_warehouse_name,
    SUM(inv.inv_quantity_on_hand) AS total_qty,
    COUNT(DISTINCT inv.inv_date_sk) AS distinct_date_cnt,
    CASE
      WHEN SUM(inv.inv_quantity_on_hand) > 500 THEN 'High'
      WHEN SUM(inv.inv_quantity_on_hand) BETWEEN 200 AND 500 THEN 'Medium'
      ELSE 'Low'
    END AS qty_category
  FROM inventory inv
  JOIN item i
    ON inv.inv_item_sk = i.i_item_sk
  JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE inv.inv_date_sk BETWEEN 2450830 AND 2451060
    AND inv.inv_quantity_on_hand > 100
    AND i.i_manager_id IN (40, 51)
    AND i.i_rec_start_date >= DATE '2000-01-01'
    AND w.w_state = 'CA'
    AND w.w_gmt_offset >= -5.00
  GROUP BY i.i_item_sk, i.i_brand, w.w_warehouse_sk, w.w_warehouse_name
)
SELECT
  qty_category,
  COUNT(DISTINCT i_brand) AS distinct_brands,
  AVG(total_qty) AS avg_total_qty,
  SUM(total_qty) AS sum_total_qty
FROM agg_inventory
GROUP BY qty_category
HAVING COUNT(DISTINCT i_brand) >= 1
ORDER BY avg_total_qty DESC
LIMIT 100
