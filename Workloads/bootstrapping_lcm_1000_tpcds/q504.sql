SELECT
    d.d_date AS return_date,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq,
    sm.sm_type AS ship_mode_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_returned_items,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_inventory_items,
    MAX(s.s_number_employees) AS max_store_employees,
    MIN(s.s_floor_space) AS min_store_floor_space,
    ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS net_loss_rank
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq,
    sm.sm_type
ORDER BY net_loss_rank
LIMIT 100
