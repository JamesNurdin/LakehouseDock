SELECT
    cc.cc_state,
    sm.sm_type,
    w.w_warehouse_name,
    cr.cr_returned_date_sk AS return_date_sk,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    AVG(cr.cr_fee) AS avg_fee,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE WHEN SUM(inv.inv_quantity_on_hand) > 0
         THEN SUM(cr.cr_return_quantity) / SUM(inv.inv_quantity_on_hand)
         ELSE NULL END AS return_to_inventory_ratio
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
   AND inv.inv_date_sk = cr.cr_returned_date_sk
WHERE cc.cc_state = 'TN'
  AND cc.cc_division IN (1, 3)
  AND sm.sm_type IN ('AIR', 'GROUND')
  AND cr.cr_return_amount > 0
  AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450200
GROUP BY cc.cc_state, sm.sm_type, w.w_warehouse_name, cr.cr_returned_date_sk
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
