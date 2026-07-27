WITH filtered_inventory AS (
    SELECT inv_date_sk,
           inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand BETWEEN 50 AND 500
      AND inv_date_sk IN (2450815, 2450948, 2450822)
)
SELECT
    i.i_item_id,
    i.i_product_name,
    COALESCE(w.w_warehouse_name, 'UNKNOWN') AS warehouse_name,
    COUNT(*) AS days_stocked,
    SUM(f.inv_quantity_on_hand) AS total_qty,
    AVG(i.i_current_price) AS avg_price,
    MIN(i.i_current_price) AS min_price,
    MAX(i.i_current_price) AS max_price
FROM filtered_inventory f
JOIN item i
    ON f.inv_item_sk = i.i_item_sk
LEFT JOIN warehouse w
    ON f.inv_warehouse_sk = w.w_warehouse_sk
    AND w.w_state = 'CA'
WHERE i.i_rec_start_date >= DATE '2000-01-01'
  AND i.i_rec_end_date > DATE '2005-12-31'
  AND i.i_brand = 'Brand#12'
  AND i.i_color = 'Red'
GROUP BY i.i_item_id,
         i.i_product_name,
         COALESCE(w.w_warehouse_name, 'UNKNOWN')
ORDER BY total_qty DESC
LIMIT 100
