SELECT
    w.w_warehouse_name,
    w.w_state,
    sm.sm_type,
    p.p_promo_name,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_fee) AS avg_fee,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_return_date,
    AVG(t.t_hour) AS avg_return_hour
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_state IN ('CA', 'TX', 'NY')
  AND sm.sm_type = 'AIR'
  AND cr.cr_return_amount > 0
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY w.w_warehouse_name, w.w_state, sm.sm_type, p.p_promo_name
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
