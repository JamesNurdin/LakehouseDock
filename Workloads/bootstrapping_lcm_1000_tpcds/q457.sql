SELECT
    s.s_state,
    s.s_city,
    sm.sm_type,
    d.d_year,
    COUNT(cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    ROUND(SUM(cr.cr_return_amount) / NULLIF(SUM(i.inv_quantity_on_hand), 0), 4) AS return_amount_per_inventory,
    ROUND(SUM(cr.cr_net_loss) / NULLIF(COUNT(cr.cr_order_number), 0), 2) AS avg_net_loss_per_return,
    MIN(d.d_date) AS first_return_date,
    MAX(d.d_date) AS last_return_date
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year >= 2018
  AND s.s_tax_percentage > 0
  AND sm.sm_carrier IS NOT NULL
GROUP BY s.s_state, s.s_city, sm.sm_type, d.d_year
HAVING COUNT(cr.cr_order_number) > 5
ORDER BY total_net_loss DESC
LIMIT 50
