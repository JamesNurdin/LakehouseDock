SELECT
    d.d_year * 100 + d.d_month_seq AS year_month,
    s.s_state,
    i.i_category,
    sm.sm_type,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_fee) AS total_fees,
    SUM(cr.cr_return_quantity * i.i_wholesale_cost) AS total_wholesale_cost,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items,
    CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS overall_loss_flag
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state IS NOT NULL
GROUP BY
    d.d_year * 100 + d.d_month_seq,
    s.s_state,
    i.i_category,
    sm.sm_type
HAVING SUM(cr.cr_return_quantity) > 20
ORDER BY year_month DESC, total_net_loss DESC
LIMIT 200
