SELECT
    d.d_year,
    d.d_quarter_name,
    sm.sm_type,
    w.w_state,
    s.s_state AS store_state,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amt,
    SUM(cr.cr_return_quantity) AS total_qty,
    AVG(w.w_gmt_offset) AS avg_warehouse_gmt_offset,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_net_loss), 0) AS return_to_loss_ratio
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year >= 2020
GROUP BY
    d.d_year,
    d.d_quarter_name,
    sm.sm_type,
    w.w_state,
    s.s_state
HAVING SUM(cr.cr_net_loss) > 0
   AND COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
