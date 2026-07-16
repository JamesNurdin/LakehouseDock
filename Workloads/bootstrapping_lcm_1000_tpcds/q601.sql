SELECT
    d.d_year,
    d.d_quarter_name,
    w.w_state,
    r.r_reason_desc,
    s.s_state AS store_state,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_fee) AS avg_fee,
    SUM(CASE WHEN cr.cr_return_ship_cost > 0 THEN cr.cr_return_ship_cost ELSE 0 END) AS total_ship_cost
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY
    d.d_year,
    d.d_quarter_name,
    w.w_state,
    r.r_reason_desc,
    s.s_state
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
