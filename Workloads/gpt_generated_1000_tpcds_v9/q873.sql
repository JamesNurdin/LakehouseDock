WITH warehouse_filter AS (
    SELECT DISTINCT w.w_warehouse_sk,
                    w.w_warehouse_id,
                    w.w_warehouse_name,
                    w.w_county,
                    w.w_street_type
    FROM warehouse w
    WHERE w.w_street_type = 'Drive'
      AND w.w_county = 'Richland County'
      AND w.w_warehouse_id IN ('15', '651', '176')
),
filtered_returns AS (
    SELECT cr.cr_warehouse_sk,
           cr.cr_ship_mode_sk,
           cr.cr_return_quantity,
           cr.cr_return_amount,
           cr.cr_return_tax,
           cr.cr_net_loss,
           cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 10
      AND cr.cr_return_tax BETWEEN 0 AND 5
      AND cr.cr_net_loss < 100
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
      AND cr.cr_returned_time_sk BETWEEN 0 AND 86400
)
SELECT wf.w_warehouse_id,
       wf.w_warehouse_name,
       wf.w_county,
       sm.sm_code,
       sm.sm_contract,
       COUNT(DISTINCT fr.cr_order_number) AS distinct_orders,
       SUM(fr.cr_return_amount) AS total_return_amount,
       AVG(fr.cr_return_quantity) AS avg_return_quantity,
       MIN(fr.cr_net_loss) AS min_net_loss,
       MAX(fr.cr_net_loss) AS max_net_loss,
       (
           SELECT SUM(cr2.cr_return_amount)
           FROM catalog_returns cr2
           WHERE cr2.cr_warehouse_sk = wf.w_warehouse_sk
       ) AS warehouse_total_return_amount,
       (
           SELECT COUNT(DISTINCT i.inv_item_sk)
           FROM inventory i
           WHERE i.inv_warehouse_sk = wf.w_warehouse_sk
             AND i.inv_quantity_on_hand > 500
       ) AS distinct_inventory_items
FROM filtered_returns fr
JOIN warehouse_filter wf
  ON fr.cr_warehouse_sk = wf.w_warehouse_sk
JOIN ship_mode sm
  ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory i
    WHERE i.inv_warehouse_sk = wf.w_warehouse_sk
      AND i.inv_quantity_on_hand > 500
      AND i.inv_item_sk IN (1, 10)
)
  AND sm.sm_code = 'AIR'
  AND sm.sm_contract = 'GNJr3g5i7oorKqtX'
GROUP BY wf.w_warehouse_id,
         wf.w_warehouse_name,
         wf.w_county,
         sm.sm_code,
         sm.sm_contract,
         wf.w_warehouse_sk
ORDER BY total_return_amount DESC
LIMIT 100
